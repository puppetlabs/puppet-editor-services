# frozen_string_literal: true

require 'json'
require 'puppet_editor_services/logging'
require 'puppet_editor_services/protocol/debug_adapter_messages'
require 'puppet_editor_services/protocol/base'

module PuppetEditorServices
  module Protocol
    class DebugAdapter < ::PuppetEditorServices::Protocol::Base
      KEY_TYPE = 'type'

      def initialize(connection)
        super(connection)

        @state = :data
        @buffer = []

        @request_sequence_id = 0
        # @requests = {}
        @request_seq_mutex = Mutex.new
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
        # Inject the sequence ID.
        raise "#{object.class} is not a PuppetEditorServices::Protocol::DebugAdapterMessages::ProtocolMessage" unless object.is_a?(PuppetEditorServices::Protocol::DebugAdapterMessages::ProtocolMessage)
        object.seq = next_sequence_id!
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
        unless json_obj[KEY_TYPE] == 'request'
          PuppetEditorServices.log_message(:error, "Unknown protocol message type #{json_obj[KEY_TYPE]}")
          return false
        end

        handler.handle(PuppetEditorServices::Protocol::DebugAdapterMessages::Request.new(json_obj))
        true
      end

      private

      def next_sequence_id!
        value = nil
        @request_seq_mutex.synchronize do
          value = @request_sequence_id
          # TODO: Do we care about integer overflow? Probably not
          @request_sequence_id += 1
        end
        value
      end
    end
  end
end
