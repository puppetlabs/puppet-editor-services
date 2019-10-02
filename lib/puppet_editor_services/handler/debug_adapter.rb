# frozen_string_literal: true

require 'puppet_editor_services/handler/base'
require 'puppet_editor_services/protocol/debug_adapter_messages'

module PuppetEditorServices
  module Handler
    class DebugAdapter < ::PuppetEditorServices::Handler::Base
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
      def handle(json_rpc_message, context = {})
        unless json_rpc_message.is_a?(PuppetEditorServices::Protocol::DebugAdapterMessages::Request)
          PuppetEditorServices.log_message(:error, "Unknown JSON RPC message type #{json_rpc_message.class}")
          return false
        end
        handle_request(json_rpc_message, context)
      end

      # Example Request
      #
      # For a textDocument/completion request
      # def request_textdocument_completion(connection_id, json_rpc_message)
      #  ...
      # end

      private

      def handle_request(request_message, _context)
        method_name = rpc_name_to_ruby_method_name('request', request_message.command)
        if respond_to?(method_name.intern)
          begin
            result = send(method_name, protocol.connection.id, request_message)
            protocol.encode_and_send(result) unless result.nil?
          rescue NoMethodError, LoadError => e
            unhandled_exception(e, :source => :request, :message => request_message)
            raise
          rescue StandardError => e
            unhandled_exception(e, :source => :request, :message => request_message)
          end
          return true
        end

        # Default processing
        protocol.encode_and_send(::PuppetEditorServices::Protocol::DebugAdapterMessages.reply_error(request_message, "This feature is not supported - Request #{request_message.command}"))
        PuppetEditorServices.log_message(:error, "Unknown request command #{request_message.command}")

        false
      end

      def rpc_name_to_ruby_method_name(prefix, rpc_name)
        name = prefix + '_' + rpc_name.tr('/', '_').tr('$', 'dollar').downcase
        name
      end
    end
  end
end
