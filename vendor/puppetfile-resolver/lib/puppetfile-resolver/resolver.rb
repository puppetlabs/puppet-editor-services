# frozen_string_literal: true

require 'molinillo'
require 'puppetfile-resolver/resolution_provider'
require 'puppetfile-resolver/resolution_result'
require 'puppetfile-resolver/models'

module PuppetfileResolver
  class Resolver
    attr_reader :puppetfile
    attr_reader :dependencies_to_resolve

    def initialize(puppetfile_document, puppet_version = nil)
      @puppetfile = puppetfile_document
      raise 'Puppetfile is not valid' unless @puppetfile.valid?
      @puppet_version = puppet_version

      @dependencies_to_resolve = dependencies_from_puppetfile
    end

    # options
    #   :cache => Cache Object
    #   :module_paths => Array[String]
    def resolve(options = {})
      if options[:ui]
        raise 'The UI object must be of type Molinillo::UI' unless options[:ui].is_a?(Molinillo::UI)
        ui = options[:ui]
      else
        require 'puppetfile-resolver/ui/null_ui'
        ui = PuppetfileResolver::UI::NullUI.new
      end
      provider = ResolutionProvider.new(@puppetfile, @puppet_version, ui, options)

      resolver = Molinillo::Resolver.new(provider, ui)
      begin
        result = resolver.resolve(dependencies_to_resolve)
      rescue Molinillo::VersionConflict => e
        # Wrap the Molinillo error
        new_e = PuppetfileResolver::Puppetfile::DocumentVersionConflictError.new(e)
        raise new_e, new_e.message, e.backtrace
      rescue Molinillo::CircularDependencyError => e
        # Wrap the Molinillo error
        new_e = PuppetfileResolver::Puppetfile::DocumentCircularDependencyError.new(@puppetfile, e)
        raise new_e, new_e.message, e.backtrace
      end
      ResolutionResult.new(result, @puppetfile)
    end

    private

    def dependencies_from_puppetfile
      result = []
      @puppetfile.modules.each do |mod|
        # Use an open version unless we get a valid version number
        if mod.version.nil? || mod.version == :latest
          version = '>= 0' # Note the `>=` is important. Don't use `>`
        else
          version = "=#{mod.version}"
        end

        result << Models::PuppetfileDependency.new(
          name: mod.title,
          version_requirement: version,
          puppetfile_module: mod
        )
      end
      # We also depend on Puppet, so add an open ended requirement if no version
      # was specified or add a strict version requirement
      if @puppet_version.nil?
        result << Models::PuppetDependency.new('>= 0')
      else
        result << Models::PuppetDependency.new(@puppet_version.to_s)
      end
      result
    end
  end
end
