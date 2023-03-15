# frozen_string_literal: true

module PuppetfileResolver
  module Puppetfile
    class DocumentValidationErrorBase
      attr_accessor :message
      attr_accessor :puppet_module

      def initialize(message, puppet_module)
        @message = message
        @puppet_module = puppet_module
      end

      def to_s
        "#{puppet_module.name}: #{message}"
      end
    end

    # Validation Error classes for parsing Puppetfiles
    class DocumentInvalidModuleError < DocumentValidationErrorBase
    end

    class DocumentDuplicateModuleError < DocumentValidationErrorBase
      attr_accessor :duplicates

      def initialize(message, puppet_module, duplicates)
        super(message, puppet_module)
        @duplicates = duplicates
      end
    end

    # Terminal Errors during resolution
    class DocumentResolveError < StandardError
      attr_reader :molinillo_error

      def initialize(message, molinillo_error)
        @molinillo_error = molinillo_error
        super(message)
      end
    end

    class DocumentCircularDependencyError < DocumentResolveError
      def initialize(puppetfile_document, molinillo_error)
        @puppetfile_document = puppetfile_document
        super(molinillo_error.message, molinillo_error)
      end

      def puppetfile_modules
        module_names = @molinillo_error.dependencies.map(&:name)
        @puppetfile_document.modules.select { |mod| module_names.include?(mod.name) }
      end
    end

    class DocumentVersionConflictError < DocumentResolveError
      def initialize(molinillo_error)
        super(molinillo_error.message_with_trees(solver_name: 'Puppetfile Resolver'), molinillo_error)
      end

      def puppetfile_modules
        puppetfile_modules = []
        molinillo_error.conflicts.reduce(''.dup) do |_o, (_name, conflict)|
          # We don't actually care about the dependency tree,
          # only the leaves within. So just grab all of leaves and
          # find all of the modules in the Puppetfile document
          conflict
            .requirement_trees
            .flatten
            .uniq
            .select { |req| req.is_a?(PuppetfileResolver::Models::PuppetfileDependency) }
            .each do |req|
              puppetfile_modules << req.puppetfile_module unless puppetfile_modules.include?(req.puppetfile_module)
            end
        end

        puppetfile_modules
      end
    end

    # Resolution Validation Error classes for validating
    # a valid Puppetfile against a dependency resolution
    class DocumentResolutionErrorBase < DocumentValidationErrorBase
      attr_accessor :puppet_module
      attr_accessor :module_specification

      def initialize(message, puppet_module, module_specification)
        super(message, puppet_module)
        @module_specification = module_specification
      end
    end

    class DocumentLatestVersionError < DocumentResolutionErrorBase
    end

    class DocumentMissingModuleError < DocumentResolutionErrorBase
    end

    class DocumentMissingDependenciesError < DocumentResolutionErrorBase
      attr_accessor :missing_specifications

      def initialize(message, puppet_module, module_specification, missing_specifications)
        super(message, puppet_module, module_specification)
        @missing_specifications = missing_specifications
      end
    end
  end
end
