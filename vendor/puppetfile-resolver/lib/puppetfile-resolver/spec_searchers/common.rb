# frozen_string_literal: true

module PuppetfileResolver
  module SpecSearchers
    module Common
      def self.dependency_cache_id(caller, dependency)
        "#{caller}-#{dependency.owner}-#{dependency.name}"
      end

      def self.specification_cache_id(caller, specification)
        "#{caller}-#{specification.owner}-#{specification.name}-#{specification.version}"
      end
    end
  end
end
