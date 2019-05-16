# frozen_string_literal: true

require 'puppet/indirector/face'

module PuppetLanguageServerSidecar
  module PuppetHelper
    SIDECAR_PUPPET_ENVIRONMENT = 'sidecarenvironment'

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

    # Function loading
    def self.retrieve_functions(cache, options = {})
      PuppetLanguageServerSidecar.log_message(:debug, '[PuppetHelper::load_functions] Starting')

      autoloader = Puppet::Util::Autoload.new(self, 'puppet/parser/functions')
      current_env = current_environment
      funcs = PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionList.new

      # Functions that are already loaded (e.g. system default functions like alert)
      # should already be populated so insert them into the function results
      #
      # Find the unique filename list
      filenames = []
      Puppet::Parser::Functions.monkey_function_list.each_value do |data|
        filenames << data[:source_location][:source] unless data[:source_location].nil? || data[:source_location][:source].nil?
      end
      # Now add the functions in each file to the cache
      filenames.uniq.compact.each do |filename|
        Puppet::Parser::Functions.monkey_function_list
                                 .select { |_k, i| filename.casecmp(i[:source_location][:source].to_s).zero? }
                                 .select { |_k, i| path_has_child?(options[:root_path], i[:source_location][:source]) }
                                 .each do |name, item|
          obj = PuppetLanguageServerSidecar::Protocol::PuppetFunction.from_puppet(name, item)
          funcs << obj
        end
      end

      # Now we can load functions from the default locations
      if autoloader.method(:files_to_load).arity.zero?
        params = []
      else
        params = [current_env]
      end
      autoloader.files_to_load(*params).each do |file|
        name = file.gsub(autoloader.path + '/', '')
        begin
          expanded_name = autoloader.expand(name)
          absolute_name = Puppet::Util::Autoload.get_file(expanded_name, current_env)
          raise("Could not find absolute path of function #{name}") if absolute_name.nil?
          if path_has_child?(options[:root_path], absolute_name) # rubocop:disable Style/IfUnlessModifier  Nicer to read like this
            funcs.concat(load_function_file(cache, name, absolute_name, autoloader, current_env))
          end
        rescue StandardError => e
          PuppetLanguageServerSidecar.log_message(:error, "[PuppetHelper::load_functions] Error loading function #{file}: #{e} #{e.backtrace}")
        end
      end

      PuppetLanguageServerSidecar.log_message(:debug, "[PuppetHelper::load_functions] Finished loading #{funcs.count} functions")
      funcs
    end

    def self.retrieve_types(cache, options = {})
      PuppetLanguageServerSidecar.log_message(:debug, '[PuppetHelper::retrieve_types] Starting')

      # From https://github.com/puppetlabs/puppet/blob/ebd96213cab43bb2a8071b7ac0206c3ed0be8e58/lib/puppet/metatype/manager.rb#L182-L189
      autoloader = Puppet::Util::Autoload.new(self, 'puppet/type')
      current_env = current_environment
      types = PuppetLanguageServer::Sidecar::Protocol::PuppetTypeList.new

      # This is an expensive call
      if autoloader.method(:files_to_load).arity.zero?
        params = []
      else
        params = [current_env]
      end
      autoloader.files_to_load(*params).each do |file|
        name = file.gsub(autoloader.path + '/', '')
        begin
          expanded_name = autoloader.expand(name)
          absolute_name = Puppet::Util::Autoload.get_file(expanded_name, current_env)
          raise("Could not find absolute path of type #{name}") if absolute_name.nil?
          if path_has_child?(options[:root_path], absolute_name) # rubocop:disable Style/IfUnlessModifier  Nicer to read like this
            types.concat(load_type_file(cache, name, absolute_name, autoloader, current_env))
          end
        rescue StandardError => e
          PuppetLanguageServerSidecar.log_message(:error, "[PuppetHelper::retrieve_types] Error loading type #{file}: #{e} #{e.backtrace}")
        end
      end

      PuppetLanguageServerSidecar.log_message(:debug, "[PuppetHelper::retrieve_types] Finished loading #{types.count} type/s")

      types
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

    def self.load_function_file(cache, name, absolute_name, autoloader, env)
      funcs = PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionList.new

      if cache.active?
        cached_result = cache.load(absolute_name, PuppetLanguageServerSidecar::Cache::FUNCTIONS_SECTION)
        unless cached_result.nil?
          begin
            funcs.from_json!(cached_result)
            return funcs
          rescue StandardError => e
            PuppetLanguageServerSidecar.log_message(:warn, "[PuppetHelper::load_function_file] Error while deserializing #{absolute_name} from cache: #{e}")
            funcs = PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionList.new
          end
        end
      end

      unless autoloader.loaded?(name)
        # This is an expensive call
        unless autoloader.load(name, env) # rubocop:disable Style/IfUnlessModifier  Nicer to read like this
          PuppetLanguageServerSidecar.log_message(:error, "[PuppetHelper::load_function_file] function #{absolute_name} did not load")
        end
      end

      # Find the functions that were loaded based on source file name (case insensitive)
      Puppet::Parser::Functions.monkey_function_list
                               .select { |_k, i| absolute_name.casecmp(i[:source_location][:source].to_s).zero? }
                               .each do |func_name, item|
        obj = PuppetLanguageServerSidecar::Protocol::PuppetFunction.from_puppet(func_name, item)
        obj.calling_source = absolute_name
        funcs << obj
      end
      PuppetLanguageServerSidecar.log_message(:warn, "[PuppetHelper::load_function_file] file #{absolute_name} did load any functions") if funcs.count.zero?
      cache.save(absolute_name, PuppetLanguageServerSidecar::Cache::FUNCTIONS_SECTION, funcs.to_json) if cache.active?

      funcs
    end
    private_class_method :load_function_file

    def self.load_type_file(cache, name, absolute_name, autoloader, env)
      types = PuppetLanguageServer::Sidecar::Protocol::PuppetTypeList.new
      if cache.active?
        cached_result = cache.load(absolute_name, PuppetLanguageServerSidecar::Cache::TYPES_SECTION)
        unless cached_result.nil?
          begin
            types.from_json!(cached_result)
            return types
          rescue StandardError => e
            PuppetLanguageServerSidecar.log_message(:warn, "[PuppetHelper::load_type_file] Error while deserializing #{absolute_name} from cache: #{e}")
            types = PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionList.new
          end
        end
      end

      # Get the list of currently loaded types
      loaded_types = []
      # Due to PUP-8301, if no types have been loaded yet then Puppet::Type.eachtype
      # will throw instead of not yielding.
      begin
        Puppet::Type.eachtype { |item| loaded_types << item.name }
      rescue NoMethodError => e
        # Detect PUP-8301
        if e.respond_to?(:receiver)
          raise unless e.name == :each && e.receiver.nil?
        else
          raise unless e.name == :each && e.message =~ /nil:NilClass/
        end
      end

      unless autoloader.loaded?(name)
        # This is an expensive call
        unless autoloader.load(name, env) # rubocop:disable Style/IfUnlessModifier  Nicer to read like this
          PuppetLanguageServerSidecar.log_message(:error, "[PuppetHelper::load_type_file] type #{absolute_name} did not load")
        end
      end

      # Find the types that were loaded
      # Due to PUP-8301, if no types have been loaded yet then Puppet::Type.eachtype
      # will throw instead of not yielding.
      begin
        Puppet::Type.eachtype do |item|
          next if loaded_types.include?(item.name)
          # Ignore the internal only Puppet Types
          next if item.name == :component || item.name == :whit
          obj = PuppetLanguageServerSidecar::Protocol::PuppetType.from_puppet(item.name, item)
          # TODO: Need to use calling_source in the cache backing store
          # Perhaps I should be incrementally adding items to the cache instead of batch mode?
          obj.calling_source = absolute_name
          types << obj
        end
      rescue NoMethodError => e
        # Detect PUP-8301
        if e.respond_to?(:receiver)
          raise unless e.name == :each && e.receiver.nil?
        else
          raise unless e.name == :each && e.message =~ /nil:NilClass/
        end
      end
      PuppetLanguageServerSidecar.log_message(:warn, "[PuppetHelper::load_type_file] type #{absolute_name} did not load any types") if types.empty?
      cache.save(absolute_name, PuppetLanguageServerSidecar::Cache::TYPES_SECTION, types.to_json) if cache.active?

      types
    end
    private_class_method :load_type_file
  end
end
