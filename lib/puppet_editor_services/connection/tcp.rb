# frozen_string_literal: true

require 'puppet_editor_services/connection/base'

module PuppetEditorServices
  module Connection
    class Tcp < ::PuppetEditorServices::Connection::Base
      attr_accessor :socket

      def initialize(server, socket)
        super(server)
        @socket = socket
      end

      def send_data(data)
        return false if socket.nil?
        socket.write(data)
        true
      end

      def close_after_writing
        socket.flush unless socket.nil?
        server.remove_connection_async(socket)
        true
      end

      def close
        server.remove_connection_async(socket)
        true
      end
    end
  end
end
