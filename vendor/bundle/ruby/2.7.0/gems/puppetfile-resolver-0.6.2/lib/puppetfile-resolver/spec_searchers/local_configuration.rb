# frozen_string_literal: true

module PuppetfileResolver
  module SpecSearchers
    class LocalConfiguration
      attr_accessor :puppet_module_paths

      def initialize
        @puppet_module_paths = []
      end
    end
  end
end
