# frozen_string_literal: true

module PuppetEditorServices
  module Connection
    class Base
      attr_reader :server
      attr_reader :protocol

      def initialize(server)
        @server = server
        @protocol = server.protocol_options[:class].new(self)
      end

      # Override this method
      # @api public
      def error?
        false
      end

      # Override this method
      # @api public
      def send_data(_data)
        false
      end

      # Shouldn't need to override this method
      # @api public
      def receive_data(data)
        @protocol.receive_data(data)
      rescue StandardError => e
        server.log("Protocol #{@protocol.class} raised error #{e}: #{e.backtrace}")
      end

      # Override this method
      # @api public
      def close_after_writing
        true
      end

      # Override this method
      # @api public
      def close
        true
      end

      # Override this method if needed
      # @api public
      def post_init
        server.log("Client #{id} has connected to the server")
      end

      # Override this method if needed
      # @api public
      def unbind
        server.log("Client #{id} has disconnected from the server")
      end

      def id
        object_id.to_s
      end
    end
  end
end
