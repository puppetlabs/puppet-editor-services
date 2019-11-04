# frozen_string_literal: true

module PuppetfileResolver
  module Models
    class ModuleDependency
      attr_accessor :name
      attr_accessor :owner
      attr_accessor :version_requirement

      def initialize(options = {})
        # Munge the name
        # "puppetlabs/stdlib"
        # "puppetlabs-stdlib"
        # "puppetlabs-stdlib-1.0.0  ??"
        # "stdlib"
        @name = options[:name]
        result = @name.split('/', 2)
        if result.count > 1
          @owner = result[0]
          @name = result[1]
        else
          result = @name.split('-')
          if result.count > 1
            @owner = result[0]
            @name = result[1]
          else
            @owner = options[:owner]
          end
        end

        @version_requirement = options[:version_requirement]
      end

      def to_s
        "#{owner}-#{name} #{version_requirement}"
      end

      def satisified_by?(spec)
        # Missing modules are special. They should always satisfy any version range because
        # we don't know what version missing modules are!
        return true if spec.is_a?(MissingModuleSpecification)
        raise "Specification #{spec} does not have a version" if spec.version.nil?
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
