# frozen_string_literal: true

require 'molinillo'
require 'puppetfile-resolver/cache/base'
require 'puppetfile-resolver/spec_searchers/forge'
require 'puppetfile-resolver/spec_searchers/git'
require 'puppetfile-resolver/spec_searchers/local'

module PuppetfileResolver
  class ResolutionProvider
    include Molinillo::SpecificationProvider

    # options
    #   module_paths : Array of paths
    #   strict_mode  : [Boolean] Whether missing dependencies throw an error (default: false)
    def initialize(puppetfile_document, puppet_version, resolver_ui, options = {})
      require 'semantic_puppet'

      @puppetfile_document = puppetfile_document
      raise 'The UI object must be of type Molinillo::UI' if resolver_ui.nil? || !resolver_ui.is_a?(Molinillo::UI)
      @resolver_ui = resolver_ui
      # TODO: This default crap should move to the resolve class and we just validate (and raise) here
      @puppet_module_paths = options[:module_paths].nil? ? [] : options[:module_paths]
      @allow_missing_modules = options[:allow_missing_modules].nil? ? true : options[:allow_missing_modules] == true
      # There can be only one puppet specification in existance so we pre-load here.
      @puppet_specification = Models::PuppetSpecification.new(puppet_version)
      @module_info = {}
      @cache = options[:cache].nil? ? Cache::Base.new : options[:cache]
    end

    # Search for the specifications that match the given dependency.
    # The specifications in the returned array will be considered in reverse
    # order, so the latest version ought to be last.
    # @note This method should be 'pure', i.e. the return value should depend
    #   only on the `dependency` parameter.
    #
    # @param [Object] dependency
    # @return [Array<Object>] the specifications that satisfy the given
    #   `dependency`.
    def search_for(dependency)
      case dependency
      when Models::PuppetDependency
        result = find_puppet_specifications(dependency)
      when Models::ModuleDependency
        result = find_all_module_specifications(dependency).select do |spec|
          dependency.satisified_by?(spec)
        end
      else
        # No idea how we got here?!?!
        raise ArgumentError, "Unknown Dependency type #{dependency.class}"
      end

      return result if result.empty? || result.count == 1
      # Reverse sort by version
      result.sort! { |a, b| a.version > b.version ? 1 : -1 }
    end

    def find_puppet_specifications(dependency)
      # Puppet specifications are a bit special as there can be only one (Highlander style)
      dependency.satisified_by?(@puppet_specification) ? [@puppet_specification] : []
    end

    # Returns the dependencies of `specification`.
    # @note This method should be 'pure', i.e. the return value should depend
    #   only on the `specification` parameter.
    #
    # @param [Object] specification
    # @return [Array<Object>] the dependencies that are required by the given
    #   `specification`.
    def dependencies_for(specification)
      specification.dependencies(@cache, @resolver_ui)
    end

    # Returns the name for the given `dependency`.
    # @note This method should be 'pure', i.e. the return value should depend
    #   only on the `dependency` parameter.
    #
    # @param [Object] dependency
    # @return [String] the name for the given `dependency`.
    def name_for(dependency)
      dependency.name
    end

    # Determines whether the given `requirement` is satisfied by the given
    # `spec`, in the context of the current `activated` dependency graph.
    #
    # @param [Object] requirement
    # @param [DependencyGraph] activated the current dependency graph in the
    #   resolution process.
    # @param [Object] spec
    # @return [Boolean] whether `requirement` is satisfied by `spec` in the
    #   context of the current `activated` dependency graph.
    def requirement_satisfied_by?(requirement, _activated, spec)
      requirement.satisified_by?(spec)
    end

    def name_for_explicit_dependency_source
      'Puppetfile'
    end

    def name_for_locking_dependency_source
      'Puppetfile'
    end

    def sort_dependencies(dependencies, activated, conflicts) # rubocop:disable Lint/UnusedMethodArgument You're drunk rubocop
      dependencies.sort_by do |dependency|
        name = name_for(dependency)
        [
          activated.vertex_named(name).payload ? 0 : 1,
          conflicts[name] ? 0 : 1
        ]
      end
    end

    # Returns whether this dependency, which has no possible matching
    # specifications, can safely be ignored.
    #
    # @param [Object] dependency
    # @return [Boolean] whether this dependency can safely be skipped.
    def allow_missing?(dependency)
      # Puppet dependencies must _always_ be resolvable
      return false if dependency.is_a?(Models::PuppetDependency)
      # Explicit Puppetfile dependencies must _always_ be resolvable
      return false if dependency.is_a?(Models::PuppetfileDependency)
      @allow_missing_modules
    end

    private

    def find_all_module_specifications(dependency)
      return @module_info[dependency.name] unless @module_info[dependency.name].nil?

      @module_info[dependency.name] = []

      # Find the module as specified in the Puppetfile?
      mod = @puppetfile_document.modules.find { |item| item.name == dependency.name }
      unless mod.nil?
        case mod.module_type
        when Puppetfile::FORGE_MODULE
          @module_info[dependency.name] = safe_spec_search(dependency) { SpecSearchers::Forge.find_all(dependency, @cache, @resolver_ui) }
        when Puppetfile::GIT_MODULE
          @module_info[dependency.name] = safe_spec_search(dependency) { SpecSearchers::Git.find_all(mod, dependency, @cache, @resolver_ui) }
        else # rubocop:disable Style/EmptyElse
          # Errr.... Nothing
        end
      end
      return @module_info[dependency.name] unless @module_info[dependency.name].empty?

      # It's not in the Puppetfile, so perhaps it's in our modulepath?
      @module_info[dependency.name] = safe_spec_search(dependency) { SpecSearchers::Local.find_all(mod, @puppet_module_paths, dependency, @cache, @resolver_ui) }
      return @module_info[dependency.name] unless @module_info[dependency.name].empty?

      # It's not in the Puppetfile and not on disk, so perhaps it's on the Forge?
      # The forge needs an owner and name to be able to resolve
      if dependency.name && dependency.owner # rubocop:disable Style/IfUnlessModifier
        @module_info[dependency.name] = safe_spec_search(dependency) { SpecSearchers::Forge.find_all(dependency, @cache, @resolver_ui) }
      end

      # If we can't find any specifications for the module and we're allowing missing modules
      # then create a MissingModuleSpecification for the purposes of the dependency graph
      if @allow_missing_modules && @module_info[dependency.name].empty? # rubocop:disable Style/IfUnlessModifier
        @module_info[dependency.name] << Models::MissingModuleSpecification.new(name: dependency.name)
      end
      @module_info[dependency.name]
    end

    def safe_spec_search(dependency)
      results = yield
      # The PuppetfileDependency has the resolver flags, so we need to inject them into the specifications
      return results unless dependency.is_a?(PuppetfileResolver::Models::PuppetfileDependency) || results.empty?
      results.each { |spec| spec.resolver_flags = dependency.puppetfile_module.resolver_flags }

      results
    rescue StandardError => e
      if @allow_missing_modules
        @resolver_ui.debug { "Error while querying a specification searcher #{e.inspect}" }
        return []
      end
      raise
    end
  end
end
