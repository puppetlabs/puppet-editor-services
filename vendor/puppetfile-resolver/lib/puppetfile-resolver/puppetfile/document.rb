# frozen_string_literal: true

require 'puppetfile-resolver/puppetfile/invalid_module'

module PuppetfileResolver
  module Puppetfile
    class DocumentLocation
      attr_accessor :start_line # Base 0
      attr_accessor :start_char # Base 0
      attr_accessor :end_line # Base 0
      attr_accessor :end_char # Base 0
    end

    class Document
      attr_accessor :forge_uri
      attr_reader   :modules
      attr_accessor :content

      def initialize(puppetfile_content)
        @content = puppetfile_content
        @modules = []
        @validation_errors = nil
      end

      def to_s
        "PuppetfileResolver::Puppetfile::Document\n#{@content}"
      end

      def clear_modules
        @modules = []
      end

      def add_module(puppet_module)
        @modules << puppet_module
      end

      def valid?
        validation_errors.empty?
      end

      def validation_errors
        return @validation_errors unless @validation_errors.nil?

        @validation_errors = []

        # Check for invalid modules
        modules.each do |mod|
          next unless mod.is_a?(PuppetfileResolver::Puppetfile::InvalidModule)
          @validation_errors << DocumentInvalidModuleError.new(mod.reason, mod)
        end

        # Check for duplicate module definitions
        dupes = modules
                .group_by { |mod| mod.name }
                .select { |_, v| v.size > 1 }
                .map(&:first)
        dupes.each do |dupe_module_name|
          duplicates = modules.select { |mod| mod.name == dupe_module_name }
          @validation_errors << DocumentDuplicateModuleError.new(
            "Duplicate module definition for '#{dupe_module_name}'",
            duplicates[0],
            duplicates.slice(1..-1)
          )
        end

        @validation_errors
      end

      def resolution_validation_errors(resolution_result)
        raise 'Validation can not be performed an an invalid document' unless valid?
        @validation_errors = []

        # Find modules which said latest but resolved to a specific version
        modules.each do |mod|
          next unless mod.version == :latest
          resolved_module = resolution_result.specifications[mod.name]
          next if resolved_module.nil? || resolved_module.is_a?(PuppetfileResolver::Models::MissingModuleSpecification)
          next if mod.resolver_flags.include?(PuppetfileResolver::Puppetfile::DISABLE_LATEST_VALIDATION_FLAG)
          @validation_errors << DocumentLatestVersionError.new(
            "Latest version of #{mod.name} is #{resolved_module.version}",
            mod,
            resolved_module
          )
        end

        # Find modules which could not be found (in the forge etc.)
        modules.each do |mod|
          resolved_module = resolution_result.specifications[mod.name]
          next unless resolved_module.is_a?(PuppetfileResolver::Models::MissingModuleSpecification)

          @validation_errors << DocumentMissingModuleError.new(
            "Could not find module #{mod.title}",
            mod,
            resolved_module
          )
        end

        # Find modules with missing dependencies
        puppetfile_module_names = modules.map(&:name)
        modules.each do |mod|
          resolved_module = resolution_result.specifications[mod.name]
          vertex = resolution_result.dependency_graph.vertex_named(mod.name)
          next if vertex.nil? || vertex.payload.nil?
          missing_successors = vertex.recursive_successors.select do |successor_vertex|
            next if successor_vertex.nil?
            next unless successor_vertex.payload.is_a?(PuppetfileResolver::Models::ModuleSpecification)
            !puppetfile_module_names.include?(successor_vertex.payload.name)
          end

          next if missing_successors.empty?
          missing_specs = missing_successors.map(&:payload)
          missing_names = missing_specs.map { |spec| "#{spec.name}-#{spec.version}" }.join(', ')
          plural = missing_successors.count == 1 ? '' : 's'
          @validation_errors << DocumentMissingDependenciesError.new(
            "Module #{mod.title} is missing dependent module#{plural}: #{missing_names}",
            mod,
            resolved_module,
            missing_specs
          )
        end

        @validation_errors
      end
    end
  end
end
