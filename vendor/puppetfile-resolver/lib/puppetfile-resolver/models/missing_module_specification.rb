# frozen_string_literal: true

require 'puppetfile-resolver/models/module_specification'

module PuppetfileResolver
  module Models
    class MissingModuleSpecification < ModuleSpecification
      def initialize(options = {})
        super
        @origin = :missing
      end

      def to_s
        "Missing #{name}"
      end

      def metadata(*_)
        nil
      end

      def dependencies(*_)
        # Modules that are missing can not depend on anything, even Puppet
        []
      end
    end
  end
end
