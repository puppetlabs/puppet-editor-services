# frozen_string_literal: true

module PuppetfileResolver
  module Models
    class PuppetDependency
      attr_reader :name
      attr_accessor :version_requirement

      def initialize(version_requirement)
        @name = 'Puppet' # This name is special as modules cannot start with an uppercase letter

        @version_requirement = version_requirement
      end

      def to_s
        "#{name} #{version_requirement}"
      end

      def satisified_by?(spec)
        # A Puppet spec with a nil version will always be satisified by a Puppet Dependency
        return true if spec.version.nil?
        semantic_requirement.include?(spec.version)
      end

      private

      def semantic_requirement
        require 'semantic_puppet'

        @semantic_requirement ||= ::SemanticPuppet::VersionRange.parse(@version_requirement)
      end
    end
  end
end
