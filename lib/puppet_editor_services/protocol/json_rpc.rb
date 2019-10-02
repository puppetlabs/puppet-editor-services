# frozen_string_literal: true

require 'json'
require 'puppet_editor_services/logging'
require 'puppet_editor_services/protocol/json_rpc_messages'
require 'puppet_editor_services/protocol/base'

module PuppetEditorServices
  module Protocol
    class JsonRPC < ::PuppetEditorServices::Protocol::Base
      CODE_INVALID_JSON       = -32700
      MSG_INVALID_JSON        = 'invalid JSON'

      CODE_INVALID_REQUEST    = -32600
      MSG_INVALID_REQ_JSONRPC = "invalid request: doesn't include \"jsonrpc\": \"2.0\""
      MSG_INVALID_REQ_ID      = 'invalid request: wrong id'
      MSG_INVALID_REQ_METHOD  = 'invalid request: wrong method'
      MSG_INVALID_REQ_PARAMS  = 'invalid request: wrong params'

      CODE_METHOD_NOT_FOUND   = -32601
      MSG_METHOD_NOT_FOUND    = 'method not found'

      CODE_INVALID_PARAMS     = -32602
      MSG_INVALID_PARAMS      = 'invalid parameter(s)'

      CODE_INTERNAL_ERROR     = -32603
      MSG_INTERNAL_ERROR      = 'internal error'

      PARSING_ERROR_RESPONSE  = '{"jsonrpc":"2.0","id":null,"error":{' \
                                "\"code\":#{CODE_INVALID_JSON}," \
                                "\"message\":\"#{MSG_INVALID_JSON}\"}}"

      BATCH_NOT_SUPPORTED_RESPONSE = '{"jsonrpc":"2.0","id":null,"error":{' \
                                      '"code":-32099,' \
                                      '"message":"batch mode not implemented"}}'

      KEY_JSONRPC     = 'jsonrpc'
      JSONRPC_VERSION = '2.0'
      KEY_ID          = 'id'
      KEY_METHOD      = 'method'
      KEY_PARAMS      = 'params'
      KEY_RESULT      = 'result'
      KEY_ERROR       = 'error'
      KEY_CODE        = 'code'
      KEY_MESSAGE     = 'message'

      def initialize(connection)
        super(connection)

        @state = :data
        @buffer = []

        @request_sequence_id = 0
        @requests = {}
        @request_mutex = Mutex.new
      end

      def extract_headers(raw_header)
        header = {}
        raw_header.split("\r\n").each do |item|
          name, value = item.split(':', 2)

          if name.casecmp('Content-Length').zero?
            header['Content-Length'] = value.strip.to_i
          elsif name.casecmp('Content-Type').zero?
            header['Content-Length'] = value.strip
          else
            raise("Unknown header #{name} in JSON message")
          end
        end
        header
      end

      def receive_data(data)
        # Inspired by https://github.com/PowerShell/PowerShellEditorServices/blob/dba65155c38d3d9eeffae5f0358b5a3ad0215fac/src/PowerShellEditorServices.Protocol/MessageProtocol/MessageReader.cs
        return if data.empty?
        return if @state == :ignore

        # TODO: Thread/Atomic safe? probably not
        @buffer += data.bytes.to_a

        while @buffer.length > 4
          # Check if we have enough data for the headers
          # Need to find the first instance of '\r\n\r\n'
          offset = 0
          while offset < @buffer.length - 4
            break if @buffer[offset] == 13 && @buffer[offset + 1] == 10 && @buffer[offset + 2] == 13 && @buffer[offset + 3] == 10
            offset += 1
          end
          return unless offset < @buffer.length - 4

          # Extract the headers
          raw_header = @buffer.slice(0, offset).pack('C*').force_encoding('ASCII') # Note the headers are always ASCII encoded
          headers = extract_headers(raw_header)
          raise('Missing Content-Length header') if headers['Content-Length'].nil?

          # Now we have the headers and the content length, do we have enough data now
          minimum_buf_length = offset + 3 + headers['Content-Length'] + 1 # Need to add one as we're converting from offset (zero based) to length (1 based) arrays
          return if @buffer.length < minimum_buf_length

          # Extract the message content
          content = @buffer.slice(offset + 3 + 1, headers['Content-Length']).pack('C*').force_encoding('utf-8') # TODO: default is utf-8.  Need to enode based on Content-Type
          # Purge the buffer
          @buffer = @buffer.slice(minimum_buf_length, @buffer.length - minimum_buf_length)
          @buffer = [] if @buffer.nil?

          PuppetEditorServices.log_message(:debug, "--- INBOUND\n#{content}\n---")
          receive_json_message_as_string(content)
        end
      end

      def send_json_string(string)
        PuppetEditorServices.log_message(:debug, "--- OUTBOUND\n#{string}\n---")

        size = string.bytesize if string.respond_to?(:bytesize)
        connection.send_data "Content-Length: #{size}\r\n\r\n" + string
      end

      def encode_and_send(object)
        send_json_string(::JSON.generate(object))
      end

      # Seperate method so async JSON processing can be supported.
      def receive_json_message_as_string(content)
        json_obj = ::JSON.parse(content)
        return receive_json_message_as_hash(json_obj) if json_obj.is_a?(Hash)
        return unless json_obj.is_a?(Array)
        # Batch: multiple requests/notifications in an array.
        # NOTE: Not implemented as it doesn't make sense using JSON RPC over pure TCP / UnixSocket.

        PuppetEditorServices.log_message(:error, 'Batch request received but not implemented')
        send_json_string BATCH_NOT_SUPPORTED_RESPONSE

        connection.close_after_writing
        @state = :ignore
      end

      def receive_json_message_as_hash(json_obj)
        # There's no need to convert it to an object quite yet
        # Need to validate that this is indeed a valid message
        unless json_obj[KEY_JSONRPC] == JSONRPC_VERSION
          PuppetEditorServices.log_message(:error, 'Invalid JSON RPC version')
          reply_error id, CODE_INVALID_REQUEST, MSG_INVALID_REQ_JSONRPC
          return false
        end

        # Requests must have an ID and Method
        is_request = json_obj.key?(KEY_ID) && json_obj.key?(KEY_METHOD)
        # Notifications must have a Method but no ID
        is_notification = json_obj.key?(KEY_METHOD) && !json_obj.key?(KEY_ID)
        # Responses must have an ID, no Method but one of Result or Error
        is_response = json_obj.key?(KEY_ID) && !json_obj.key?(KEY_METHOD) && (json_obj.key?(KEY_RESULT) || json_obj.key?(KEY_ERROR))

        # The 'params' attribute must be a hash or an array
        if (params = json_obj[KEY_PARAMS])
          unless params.is_a?(Array) || params.is_a?(Hash)
            reply_error id, CODE_INVALID_REQUEST, MSG_INVALID_REQ_PARAMS
            return false
          end
        end

        id = json_obj[KEY_ID]
        # Requests and Responses must have an ID that is either a string or integer
        if is_request || is_response
          unless id.is_a?(String) || id.is_a?(Integer)
            reply_error nil, CODE_INVALID_REQUEST, MSG_INVALID_REQ_ID
            return false
          end
        end

        # Requests and Notifications must have a method
        if is_request || is_notification
          unless (json_obj[KEY_METHOD]).is_a? String
            reply_error id, CODE_INVALID_REQUEST, MSG_INVALID_REQ_METHOD
            return false
          end
        end

        # Responses must have a matching request originating from this instance
        # Otherwise ignore it
        if is_response
          original_request = client_request!(json_obj[KEY_ID])
          return false if original_request.nil?
        end

        if is_request
          handler.handle(PuppetEditorServices::Protocol::JsonRPCMessages::RequestMessage.new(json_obj))
          return true
        elsif is_notification
          handler.handle(PuppetEditorServices::Protocol::JsonRPCMessages::NotificationMessage.new(json_obj))
          return true
        elsif is_response
          # Responses are special as they need the context of the original request
          handler.handle(PuppetEditorServices::Protocol::JsonRPCMessages::ResponseMessage.new(json_obj), :request => original_request)
          return true
        end
        false
      end

      # region Server-to-Client request/response methods
      def send_client_request(rpc_method, params)
        request = ::PuppetEditorServices::Protocol::JsonRPCMessages.new_request(client_request_id!, rpc_method, params)
        encode_and_send(request)
        add_client_request(request)
        request.id
      end

      # Thread-safe way to get a new request id
      def client_request_id!
        value = nil
        @request_mutex.synchronize do
          value = @request_sequence_id
          @request_sequence_id += 1
        end
        value
      end

      # Stores the request so it can later be correlated with an
      # incoming repsonse
      def add_client_request(request)
        @request_mutex.synchronize do
          @requests[request.id] = request
        end
      end

      # Retrieve the request to a client. Note that this removes it
      # from the requests queue.
      def client_request!(id)
        value = nil
        @request_mutex.synchronize do
          unless @requests[id].nil?
            value = @requests[id]
            @requests.delete(id)
          end
        end
        value
      end
      # endregion
    end
  end
end
