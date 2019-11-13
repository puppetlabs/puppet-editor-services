# frozen_string_literal: true

require 'puppet_editor_services/server'
require 'puppet_editor_services/connection/base'
require 'puppet_editor_services/protocol/base'

module PuppetEditorServices
  module Server
    class Base
      attr_reader :server_options
      attr_reader :connection_options
      attr_reader :protocol_options
      attr_reader :handler_options

      def name
        'SRV'
      end

      def initialize(server_options, connection_options, protocol_options, handler_options)
        @server_options = server_options.nil? ? {} : server_options.dup
        @connection_options = connection_options.nil? ? {} : connection_options.dup
        @protocol_options = protocol_options.nil? ? {} : protocol_options.dup
        @handler_options = handler_options.nil? ? {} : handler_options.dup

        @connection_options[:class] = PuppetEditorServices::Connection::Base if @connection_options[:class].nil?
        @protocol_options[:class] = PuppetEditorServices::Protocol::Base if @protocol_options[:class].nil?
        @handler_options[:class] = PuppetEditorServices::Handler::Base if @handler_options[:class].nil?

        @server_options[:servicename] = 'LANGUAGE SERVER' if @server_options[:servicename].nil?

        # Assumes there's only ONE active simpler server running at a time.
        PuppetEditorServices::Server.current_server = self
      end

      # Returns a client connection for a given connection_id
      def connection(connection_id); end

      def start; end

      def log(message)
        PuppetEditorServices.log_message(:debug, "#{name}: #{message}")
      end
    end
  end
end
