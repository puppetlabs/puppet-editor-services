# frozen_string_literal: true

module PuppetEditorServices
  module Protocol
    class Base
      attr_reader :connection
      attr_reader :handler

      def initialize(connection)
        @connection = connection
        @handler = connection.server.handler_options[:class].new(self)
      end

      # @abstract
      def receive_data(data); end

      def close_connection
        connection.close unless connection.nil?
      end

      def connection_error?
        return false if connection.nil?
        connection.error?
      end
    end
  end
end
