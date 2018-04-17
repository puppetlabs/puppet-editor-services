module PuppetEditorServices
  class SimpleServerConnectionBase
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

    # Override this method
    # @api public
    def close_connection_after_writing
      true
    end

    # Override this method
    # @api public
    def close_connection
      true
    end
  end

  class SimpleServerConnectionHandler
    attr_accessor :client_connection

    # Override this method
    # @api public
    def receive_data(_data)
      false
    end

    # Override this method
    # @api public
    def post_init
      true
    end

    # Override this method
    # @api public
    def unbind
      true
    end
  end
end
