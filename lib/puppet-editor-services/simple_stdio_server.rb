module PuppetEditorServices
  class SimpleSTDIOServerConnection < SimpleServerConnectionBase
    attr_accessor :socket

    def initialize(socket)
      @socket = socket
    end

    def send_data(data)
      return false if socket.nil?
      socket.write(data)
      true
    end

    def close_connection_after_writing
      socket.flush unless socket.nil?
      simple_tcp_server.remove_connection_async(socket)
      true
    end

    def close_connection
      simple_tcp_server.remove_connection_async(socket)
      true
    end
  end
end
