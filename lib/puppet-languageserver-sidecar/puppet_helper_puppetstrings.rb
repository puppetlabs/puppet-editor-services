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
      %I[function type]
    end

    # Retrieve objects via the Puppet 4 API loaders
    def self.retrieve_via_puppet_strings(_cache, options = {})
      PuppetLanguageServerSidecar.log_message(:debug, '[PuppetHelper::retrieve_via_pup4_api] Starting')

      object_types = options[:object_types].nil? ? available_documentation_types : options[:object_types]
      object_types.select! { |i| available_documentation_types.include?(i) }

      result = {}
      return result if object_types.empty?

      result[:functions] = PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionList.new if object_types.include?(:function)
      result[:types]     = PuppetLanguageServer::Sidecar::Protocol::PuppetTypeList.new if object_types.include?(:type)

      current_env = current_environment
      for_agent = options[:for_agent].nil? ? true : options[:for_agent]
      loaders = Puppet::Pops::Loaders.new(current_env, for_agent)
      # Add any custom loaders
      path_discoverer_loader = Puppet::Pops::Loader::PathDiscoveryNullLoader.new(nil, DISCOVERER_LOADER)
      loaders.add_loader_by_name(path_discoverer_loader)

      paths = []
      paths.concat(discover_type_paths(:function, loaders)) if object_types.include?(:function)
      paths.concat(discover_type_paths(:type, loaders)) if object_types.include?(:type)

      paths.each do |path|
        next unless path_has_child?(options[:root_path], path)
        file_doc = PuppetLanguageServerSidecar::PuppetStringsHelper.file_documentation(path)
        next if file_doc.nil?

        if object_types.include?(:function) # rubocop:disable Style/IfUnlessModifier   This reads better
          file_doc.functions.each { |_name, item| result[:functions] << item }
        end
        if object_types.include?(:type)
          file_doc.types.each do |name, item|
            result[:types] << item unless name == 'whit' || name == 'component' # rubocop:disable Style/MultipleComparison
          end
        end
      end

      # Remove Puppet3 functions which have a Puppet4 function already loaded
      if object_types.include?(:function)
        pup4_functions = result[:functions].select { |i| i.function_version == 4 }.map { |i| i.key }
        result[:functions].reject! { |i| i.function_version == 3 && pup4_functions.include?(i.key) }
      end

      result
    end

    def self.discover_type_paths(type, loaders)
      [].concat(
        loaders.private_environment_loader.discover_paths(type),
        loaders[DISCOVERER_LOADER].discover_paths(type)
      )
    end

    # Class and Defined Type loading
    def self.retrieve_classes(cache, options = {})
      PuppetLanguageServerSidecar.log_message(:debug, '[PuppetHelper::retrieve_classes] Starting')

      # TODO: Can probably do this better, but this works.
      current_env = current_environment
      module_path_list = current_env
                         .modules
                         .select { |mod| Dir.exist?(File.join(mod.path, 'manifests')) }
                         .map { |mod| mod.path }
      manifest_path_list = module_path_list.map { |mod_path| File.join(mod_path, 'manifests') }
      PuppetLanguageServerSidecar.log_message(:debug, "[PuppetHelper::retrieve_classes] Loading classes from #{module_path_list}")

      # Find and parse all manifests in the manifest paths
      classes = PuppetLanguageServer::Sidecar::Protocol::PuppetClassList.new
      manifest_path_list.each do |manifest_path|
        Dir.glob("#{manifest_path}/**/*.pp").each do |manifest_file|
          begin
            if path_has_child?(options[:root_path], manifest_file) # rubocop:disable Style/IfUnlessModifier  Nicer to read like this
              classes.concat(load_classes_from_manifest(cache, manifest_file))
            end
          rescue StandardError => e
            PuppetLanguageServerSidecar.log_message(:error, "[PuppetHelper::retrieve_classes] Error loading manifest #{manifest_file}: #{e} #{e.backtrace}")
          end
        end
      end

      PuppetLanguageServerSidecar.log_message(:debug, "[PuppetHelper::retrieve_classes] Finished loading #{classes.count} classes")
      classes
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

    def self.load_classes_from_manifest(cache, manifest_file)
      class_info = PuppetLanguageServer::Sidecar::Protocol::PuppetClassList.new

      if cache.active?
        cached_result = cache.load(manifest_file, PuppetLanguageServerSidecar::Cache::CLASSES_SECTION)
        unless cached_result.nil?
          begin
            class_info.from_json!(cached_result)
            return class_info
          rescue StandardError => e
            PuppetLanguageServerSidecar.log_message(:warn, "[PuppetHelper::load_classes_from_manifest] Error while deserializing #{manifest_file} from cache: #{e}")
            class_info = PuppetLanguageServer::Sidecar::Protocol::PuppetClassList.new
          end
        end
      end

      file_content = File.open(manifest_file, 'r:UTF-8') { |f| f.read }

      parser = Puppet::Pops::Parser::Parser.new
      result = nil
      begin
        result = parser.parse_string(file_content, '')
      rescue Puppet::ParseErrorWithIssue
        # Any parsing errors means we can't inspect the document
        return class_info
      end

      # Enumerate the entire AST looking for classes and defined types
      # TODO: Need to learn how to read the help/docs for hover support
      if result.model.respond_to? :eAllContents
        # Puppet 4 AST
        result.model.eAllContents.select do |item|
          puppet_class = {}
          case item.class.to_s
          when 'Puppet::Pops::Model::HostClassDefinition'
            puppet_class['type'] = :class
          when 'Puppet::Pops::Model::ResourceTypeDefinition'
            puppet_class['type'] = :typedefinition
          else
            next
          end
          puppet_class['name']       = item.name
          puppet_class['doc']        = nil
          puppet_class['parameters'] = item.parameters
          puppet_class['source']     = manifest_file
          puppet_class['line']       = result.locator.line_for_offset(item.offset) - 1
          puppet_class['char']       = result.locator.offset_on_line(item.offset)

          obj = PuppetLanguageServerSidecar::Protocol::PuppetClass.from_puppet(item.name, puppet_class, result.locator)
          class_info << obj
        end
      else
        result.model._pcore_all_contents([]) do |item|
          puppet_class = {}
          case item.class.to_s
          when 'Puppet::Pops::Model::HostClassDefinition'
            puppet_class['type'] = :class
          when 'Puppet::Pops::Model::ResourceTypeDefinition'
            puppet_class['type'] = :typedefinition
          else
            next
          end
          puppet_class['name']       = item.name
          puppet_class['doc']        = nil
          puppet_class['parameters'] = item.parameters
          puppet_class['source']     = manifest_file
          puppet_class['line']       = item.line
          puppet_class['char']       = item.pos
          obj = PuppetLanguageServerSidecar::Protocol::PuppetClass.from_puppet(item.name, puppet_class, item.locator)
          class_info << obj
        end
      end
      cache.save(manifest_file, PuppetLanguageServerSidecar::Cache::CLASSES_SECTION, class_info.to_json) if cache.active?

      class_info
    end
    private_class_method :load_classes_from_manifest
  end
end
