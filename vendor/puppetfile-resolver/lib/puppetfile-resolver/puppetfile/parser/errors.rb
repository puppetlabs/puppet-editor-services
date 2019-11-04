# frozen_string_literal: true

module PuppetfileResolver
  module Puppetfile
    module Parser
      class ParserError < RuntimeError
        attr_accessor :location

        def initialize(error_message)
          @error_message = error_message
        end

        def to_s
          @error_message
        end
      end
    end
  end
end
