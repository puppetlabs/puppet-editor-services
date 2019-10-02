# frozen_string_literal: true

require 'puppet_editor_services/handler/base'
require 'puppet_editor_services/protocol/json_rpc_messages'

module PuppetEditorServices
  module Handler
    class JsonRPC < ::PuppetEditorServices::Handler::Base
      def initialize(protocol)
        super(protocol)
      end

      # options
      #    source        :request, :notification etc.
      #    message       JSON Message that caused the error
      #    error         Actual ruby error
      # @abstract
      def unhandled_exception(error, options)
        PuppetEditorServices.log_message(:error, "Unhandled exception from #{options[:source]}. JSON Message #{options[:message]}: #{error.inspect}\n#{error.backtrace}")
      end

      # context
      #   request => original request
      def handle(json_rpc_message, context = {})
        case json_rpc_message

        when ::PuppetEditorServices::Protocol::JsonRPCMessages::RequestMessage
          return handle_request(json_rpc_message, context)

        when ::PuppetEditorServices::Protocol::JsonRPCMessages::NotificationMessage
          return handle_notification(json_rpc_message, context)

        when ::PuppetEditorServices::Protocol::JsonRPCMessages::ResponseMessage
          return handle_response(json_rpc_message, context)

        else
          PuppetEditorServices.log_message(:error, "Unknown JSON RPC message type #{json_rpc_message.class}")
        end
        false
      end

      # Example Request
      #
      # For a textDocument/completion request
      # def request_textdocument_completion(connection_id, json_rpc_message)
      #  ...
      # end

      # Example Notification
      # For a workspace/didChangeNotification notification
      # def notification_workspace_didchangeconfiguration(connection_id, json_rpc_message)
      #  ...
      # end

      # Example Response
      # A response to a client/registerCapability request
      # def notification_workspace_didchangeconfiguration(connection_id, json_rpc_message, original_request)
      #  ...
      # end

      private

      def handle_request(request_message, _context)
        method_name = rpc_name_to_ruby_method_name('request', request_message.rpc_method)
        if respond_to?(method_name.intern)
          begin
            protocol.encode_and_send(
              ::PuppetEditorServices::Protocol::JsonRPCMessages.reply_result(
                request_message, send(method_name, protocol.connection.id, request_message)
              )
            )
          rescue StandardError => e
            unhandled_exception(e, :source => :request, :message => request_message)
          end
          return true
        end

        # Default processing
        protocol.encode_and_send(::PuppetEditorServices::Protocol::JsonRPCMessages.reply_method_not_found(request_message))
        if request_message.rpc_method.start_with?('$/')
          PuppetEditorServices.log_message(:debug, "Ignoring RPC request #{request_message.rpc_method}")
        else
          PuppetEditorServices.log_message(:error, "Unknown RPC method #{request_message.rpc_method}")
        end

        false
      end

      def handle_notification(notification_message, _context)
        method_name = rpc_name_to_ruby_method_name('notification', notification_message.rpc_method)
        if respond_to?(method_name.intern)
          begin
            send(method_name, protocol.connection.id, notification_message)
          rescue StandardError => e
            unhandled_exception(e, :source => :notification, :message => notification_message)
          end
          return true
        end

        # Default processing
        if notification_message.rpc_method.start_with?('$/')
          PuppetEditorServices.log_message(:debug, "Ignoring RPC notification #{notification_message.rpc_method}")
        else
          PuppetEditorServices.log_message(:error, "Unknown RPC notification #{notification_message.rpc_method}")
        end

        false
      end

      def handle_response(response_message, context)
        original_request = context[:request]
        return false if original_request.nil?
        unless response_message.is_successful # rubocop:disable Style/IfUnlessModifier Line is too long otherwise
          PuppetEditorServices.log_message(:error, "Response for method '#{original_request.rpc_method}' with id '#{original_request.id}' failed with #{response_message.error}")
        end
        method_name = rpc_name_to_ruby_method_name('response', original_request.rpc_method)
        if respond_to?(method_name.intern)
          begin
            send(method_name, protocol.connection.id, response_message, original_request)
          rescue StandardError => e
            unhandled_exception(e, :source => :response, :message => response_message)
          end
          return true
        end

        # Default processing
        PuppetEditorServices.log_message(:error, "Unknown RPC response for method #{original_request.rpc_method}")
        false
      end

      def rpc_name_to_ruby_method_name(prefix, rpc_name)
        name = prefix + '_' + rpc_name.tr('/', '_').tr('$', 'dollar').downcase
        name
      end
    end
  end
end
