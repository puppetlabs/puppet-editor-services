# frozen_string_literal: true

require 'puppet/indirector/face'

module PuppetLanguageServerSidecar
  module PuppetHelper
    SIDECAR_PUPPET_ENVIRONMENT = 'sidecarenvironment'
    DISCOVERER_LOADER = 'path-discoverer-null-loader'

    def self.path_has_child?(path, child)
      # Doesn't matter what the child is, if the path is nil it's true.
      return true if path.nil?
      return false if path.length >= child.length

      value = child.slice(0, path.length)
      return true if value.casecmp(path).zero?
      false
    end

    # Resource Face
    def self.get_puppet_resource(typename, title = nil)
      result = PuppetLanguageServer::Sidecar::Protocol::PuppetClassList.new
      if title.nil?
        resources = Puppet::Face[:resource, '0.0.1'].search(typename)
      else
        resources = Puppet::Face[:resource, '0.0.1'].find("#{typename}/#{title}")
      end
      return result if resources.nil?
      resources = [resources] unless resources.is_a?(Array)
      prune_resource_parameters(resources).each do |item|
        obj = PuppetLanguageServer::Sidecar::Protocol::Resource.new
        obj.manifest = item.to_manifest
        result << obj
      end
      result
    end

    # Puppet Strings loading
    def self.available_documentation_types
      %I[class function type]
    end

    # Retrieve objects via the Puppet 4 API loaders
    def self.retrieve_via_puppet_strings(cache, options = {})
      PuppetLanguageServerSidecar.log_message(:debug, '[PuppetHelper::retrieve_via_puppet_strings] Starting')

      object_types = options[:object_types].nil? ? available_documentation_types : options[:object_types]
      object_types.select! { |i| available_documentation_types.include?(i) }

      result = PuppetLanguageServer::Sidecar::Protocol::AggregateMetadata.new
      return result if object_types.empty?

      current_env = current_environment
      for_agent = options[:for_agent].nil? ? true : options[:for_agent]
      loaders = Puppet::Pops::Loaders.new(current_env, for_agent)
      # Add any custom loaders
      path_discoverer_loader = Puppet::Pops::Loader::PathDiscoveryNullLoader.new(nil, DISCOVERER_LOADER)
      loaders.add_loader_by_name(path_discoverer_loader)

      paths = []
      # :sidecar_manifest isn't technically a Loadable thing. This is useful because we know that any type
      # of loader will just ignore it.
      paths.concat(discover_type_paths(:sidecar_manifest, loaders)) if object_types.include?(:class)
      paths.concat(discover_type_paths(:function, loaders)) if object_types.include?(:function)
      paths.concat(discover_type_paths(:type, loaders)) if object_types.include?(:type)

      paths.each do |path|
        next unless path_has_child?(options[:root_path], path)
        file_doc = PuppetLanguageServerSidecar::PuppetStringsHelper.file_documentation(path, cache)
        next if file_doc.nil?

        if object_types.include?(:class) # rubocop:disable Style/IfUnlessModifier   This reads better
          file_doc.classes.each { |item| result.append!(item) }
        end
        if object_types.include?(:function) # rubocop:disable Style/IfUnlessModifier   This reads better
          file_doc.functions.each { |item| result.append!(item) }
        end
        if object_types.include?(:type)
          file_doc.types.each do |item|
            result.append!(item) unless name == 'whit' || name == 'component' # rubocop:disable Style/MultipleComparison
          end
        end
      end

      # Remove Puppet3 functions which have a Puppet4 function already loaded
      if object_types.include?(:function) && !result.functions.nil?
        pup4_functions = result.functions.select { |i| i.function_version == 4 }.map { |i| i.key }
        result.functions.reject! { |i| i.function_version == 3 && pup4_functions.include?(i.key) }
      end

      result.each_list { |key, item| PuppetLanguageServerSidecar.log_message(:debug, "[PuppetHelper::retrieve_via_puppet_strings] Finished loading #{item.count} #{key}") }
      result
    end

    def self.discover_type_paths(type, loaders)
      [].concat(
        loaders.private_environment_loader.discover_paths(type),
        loaders[DISCOVERER_LOADER].discover_paths(type)
      )
    end

    # Private functions

    def self.prune_resource_parameters(resources)
      # From https://github.com/puppetlabs/puppet/blob/488661d84e54904124514ab9e4500e81b10f84d1/lib/puppet/application/resource.rb#L146-L148
      if resources.is_a?(Array)
        resources.map(&:prune_parameters)
      else
        resources.prune_parameters
      end
    end
    private_class_method :prune_resource_parameters

    def self.current_environment
      begin
        env = Puppet.lookup(:environments).get!(Puppet.settings[:environment])
        return env unless env.nil?
      rescue Puppet::Environments::EnvironmentNotFound
        PuppetLanguageServerSidecar.log_message(:warning, "[PuppetHelper::current_environment] Unable to load environment #{Puppet.settings[:environment]}")
      rescue StandardError => e
        PuppetLanguageServerSidecar.log_message(:warning, "[PuppetHelper::current_environment] Error loading environment #{Puppet.settings[:environment]}: #{e}")
      end
      Puppet.lookup(:current_environment)
    end
    private_class_method :current_environment
  end
end
