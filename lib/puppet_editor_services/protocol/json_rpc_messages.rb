# frozen_string_literal: true

require 'puppet_editor_services/protocol/json_rpc'

module PuppetEditorServices
  module Protocol
    module JsonRPCMessages
      # Protocol message primitives
      class Message
        attr_accessor :jsonrpc

        def initialize(initial_hash = nil)
          @jsonrpc = ::PuppetEditorServices::Protocol::JsonRPC::JSONRPC_VERSION
          from_h!(initial_hash)
        end

        def from_h!(value)
          return self if value.nil? || value.empty?
          # jsonrpc is a little special.  Don't override it with nil. This
          # allows `.new.from_h!(..)` to use the default without knowing exactly
          # what version is used.
          self.jsonrpc = value['jsonrpc'] unless value['jsonrpc'].nil?
          self
        end

        def to_json(*options)
          to_h.to_json(options)
        end

        def to_h
          {
            'jsonrpc' => jsonrpc
          }
        end
      end

      # interface RequestMessage extends Message {
      #   /**
      #    * The request id.
      #    */
      #   id: number | string;
      #   /**
      #    * The method to be invoked.
      #    */
      #   method: string;
      #   /**
      #    * The method's params.
      #    */
      #   params?: Array<any> | object;
      # }
      class RequestMessage < Message
        attr_accessor :id
        attr_accessor :rpc_method
        attr_accessor :params

        def initialize(initial_hash = nil)
          super
        end

        def from_h!(value)
          value = {} if value.nil?
          super(value)
          self.id = value['id']
          self.rpc_method = value['method']
          self.params = value['params']
          self
        end

        def to_h
          super.merge(
            'id'     => id,
            'method' => rpc_method,
            'params' => params
          )
        end
      end

      # interface NotificationMessage extends Message {
      #   /**
      #     * The method to be invoked.
      #     */
      #   method: string;

      #   /**
      #     * The notification's params.
      #     */
      #   params?: Array<any> | object;
      # }
      class NotificationMessage < Message
        attr_accessor :rpc_method
        attr_accessor :params

        def initialize(initial_hash = nil)
          super
        end

        def from_h!(value)
          value = {} if value.nil?
          super(value)
          self.rpc_method = value['method']
          self.params = value['params']
          self
        end

        def to_h
          hash = { 'method' => rpc_method }
          hash['params'] = params unless params.nil?
          super.merge(hash)
        end
      end

      # interface ResponseMessage extends Message {
      #   /**
      #     * The request id.
      #     */
      #   id: number | string | null;

      #   /**
      #     * The result of a request. This member is REQUIRED on success.
      #     * This member MUST NOT exist if there was an error invoking the method.
      #     */
      #   result?: string | number | boolean | object | null;

      #   /**
      #     * The error object in case a request fails.
      #     */
      #   error?: ResponseError<any>;
      # }
      class ResponseMessage < Message
        attr_accessor :id
        attr_accessor :result
        attr_accessor :error
        # is_successful is special. It changes based on deserialising from hash or
        # can be manually set. This affects serialisation
        attr_accessor :is_successful

        def initialize(initial_hash = nil)
          super
        end

        def from_h!(value)
          value = {} if value.nil?
          super(value)
          self.id = value['id']
          self.result = value['result']
          self.error = value['error']
          self.is_successful = value.key?('result')
          self
        end

        def to_h
          hash = { 'id' => id }
          # Ref - https://www.jsonrpc.org/specification#response_object
          if is_successful
            # Succesful responses must ALWAYS have the result key, even if it's null.
            hash['result'] = result
          else
            # Error responses must ALWAYS have the error key
            # TODO: The RPC spec says error MUST be an Error object, not nil.
            hash['error'] = error
          end
          super.merge(hash)
        end
      end

      # Static message generators
      def self.reply_result(request, result)
        ResponseMessage.new.from_h!('id' => request.id, 'result' => result)
      end

      def self.reply_error(request, code, message)
        # Note - Strictly speaking the error should be typed object, however as this hidden behind
        # this method it's easier to just pass in a known hash construct
        ResponseMessage.new.from_h!(
          'id'    => request.id,
          'error' => {
            'code'    => code,
            'message' => message
          }
        )
      end

      def self.reply_method_not_found(request, message = nil)
        reply_error(
          request,
          ::PuppetEditorServices::Protocol::JsonRPC::CODE_METHOD_NOT_FOUND,
          message || ::PuppetEditorServices::Protocol::JsonRPC::MSG_METHOD_NOT_FOUND
        )
      end

      def self.new_notification(method_name, params)
        NotificationMessage.new.from_h!('method' => method_name, 'params' => params)
      end

      def self.new_request(id, method_name, params)
        RequestMessage.new.from_h!('id' => id, 'method' => method_name, 'params' => params)
      end
    end
  end
end
