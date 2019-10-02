# frozen_string_literal: true

module PuppetEditorServices
  module Handler
    class Base
      attr_reader :protocol

      def initialize(protocol)
        @protocol = protocol
      end

      # @abstract
      def handle(_message, _context = {}); end
    end
  end
end
