# frozen_string_literal: true

module PuppetfileResolver
  module Models
    class PuppetfileDependency < ModuleDependency
      attr_reader :puppetfile_module

      def initialize(options = {})
        super(options)
        @puppetfile_module = options[:puppetfile_module]
      end
    end
  end
end
