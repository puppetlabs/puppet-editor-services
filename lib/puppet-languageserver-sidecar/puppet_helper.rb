# frozen_string_literal: true

require 'puppet/indirector/face'

module PuppetLanguageServerSidecar
  module PuppetHelper
    SIDECAR_PUPPET_ENVIRONMENT = 'sidecarenvironment'

    # Ignore certain data types. For more information see https://tickets.puppetlabs.com/browse/DOCUMENT-1020
    # TypeReference - Internal to the Puppet Data Type system
    # TypeAlias - Internal to the Puppet Data Type system
    # Object - While useful, typically only needed when extended the type system as opposed to general use
    # TypeSet - While useful, typically only needed when extended the type system as opposed to general use
    IGNORE_DATATYPE_NAMES = %w[TypeReference TypeAlias Object TypeSet ObjectTypeExten Iterable AbstractTimeData TypeWithContained].freeze

    # Resource Face
    def self.get_puppet_resource(typename, title = nil)
      result = PuppetLanguageServer::Sidecar::Protocol::PuppetClassList.new
      resources = if title.nil?
                    Puppet::Face[:resource, '0.0.1'].search(typename)
                  else
                    Puppet::Face[:resource, '0.0.1'].find("#{typename}/#{title}")
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
      %I[class datatype function type]
    end

    def self.retrieve_default_data_types
      default_types = PuppetLanguageServer::Sidecar::Protocol::PuppetDataTypeList.new
      # There's no actual record of all available types, but we can use the Puppet::Pops::Types to implicitly get their names
      name_list = []

      Puppet::Pops::Types.constants.each do |const|
        thing = Puppet::Pops::Types.const_get(const)
        # Not that this is a reference to a type, not an INSTANCE of that type.
        # So we can't do .is_a? checks. But instead look for methods on the thing
        # that would indicate it's a Puppet Type
        #   _pcore_type : is present on all Pops type objects
        #   simple_name : comes from PAnyType
        next unless thing.respond_to?(:_pcore_type) && thing.respond_to?(:simple_name)
        # Ignore certain data types
        next if IGNORE_DATATYPE_NAMES.include?(thing.simple_name)
        # Don't need duplicates
        next if name_list.include?(thing.simple_name)

        name_list << thing.simple_name

        obj                = PuppetLanguageServer::Sidecar::Protocol::PuppetDataType.new
        obj.key            = thing.simple_name
        obj.source         = nil
        obj.calling_source = nil
        obj.line           = nil
        obj.doc            = "The #{thing.simple_name} core data type"
        obj.is_type_alias  = false
        obj.alias_of       = nil
        # So far, no core data types have attributes
        obj.attributes     = []
        default_types << obj
      end

      default_types
    end
    private_class_method :retrieve_default_data_types

    # Retrieve objects via the Puppet 4 API loaders
    def self.retrieve_via_puppet_strings(cache, options = {})
      PuppetLanguageServerSidecar.log_message(:debug, '[PuppetHelper::retrieve_via_puppet_strings] Starting')

      object_types = options[:object_types].nil? ? available_documentation_types : options[:object_types]
      object_types.select! { |i| available_documentation_types.include?(i) }

      result = PuppetLanguageServer::Sidecar::Protocol::AggregateMetadata.new
      return result if object_types.empty?

      current_env = current_environment
      for_agent = options[:for_agent].nil? || options[:for_agent]
      Puppet::Pops::Loaders.new(current_env, for_agent)

      finder = PuppetPathFinder.new(current_env, object_types)
      paths = finder.find(options[:root_path])

      paths.each do |path|
        file_doc = PuppetLanguageServerSidecar::PuppetStringsHelper.file_documentation(path, finder.puppet_path, cache)
        next if file_doc.nil?

        if object_types.include?(:class) # rubocop:disable Style/IfUnlessModifier -- This reads better
          file_doc.classes.each { |item| result.append!(item) }
        end
        if object_types.include?(:datatype) # rubocop:disable Style/IfUnlessModifier -- This reads better
          file_doc.datatypes.each { |item| result.append!(item) }
        end
        if object_types.include?(:function) # rubocop:disable Style/IfUnlessModifier -- This reads better
          file_doc.functions.each { |item| result.append!(item) }
        end
        next unless object_types.include?(:type)

        file_doc.types.each do |item|
          result.append!(item) unless %w[whit component].include?(name)
          finder.temp_file.unlink if item.key == 'file' && File.exist?(finder.temp_file.path) # Remove the temp_file.rb if it exists
        end
      end

      # Remove Puppet3 functions which have a Puppet4 function already loaded
      if object_types.include?(:function) && !result.functions.nil?
        pup4_functions = result.functions.select { |i| i.function_version == 4 }.map { |i| i.key }
        result.functions.reject! { |i| i.function_version == 3 && pup4_functions.include?(i.key) }
      end

      # Add the inbuilt data types if there's no root path
      result.concat!(retrieve_default_data_types) if object_types.include?(:datatype) && options[:root_path].nil?

      result.each_list { |key, item| PuppetLanguageServerSidecar.log_message(:debug, "[PuppetHelper::retrieve_via_puppet_strings] Finished loading #{item.count} #{key}") }
      result
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

    # A helper class to find the paths for different kinds of things related to Puppet, for example
    # DataType ruby files or manifests.
    class PuppetPathFinder
      attr_reader :object_types, :puppet_path, :temp_file

      # @param puppet_env [Puppet::Node::Environment] The environment to search within
      # @param object_types [Symbol] The types of objects that will be searched for. See available_documentation_types for the complete list
      def initialize(puppet_env, object_types)
        # Path to every module
        @module_paths = puppet_env.modules.map(&:path)
        # Path to the environment
        @env_path = puppet_env.configuration.path_to_env
        # Path to the puppet installation
        @puppet_path = if puppet_env.loaders.nil? # No loaders have been created yet
                         nil
                       elsif puppet_env.loaders.puppet_system_loader.nil?
                         nil
                       elsif puppet_env.loaders.puppet_system_loader.lib_root?
                         File.join(puppet_env.loaders.puppet_system_loader.path, '..')
                       else
                         puppet_env.loaders.puppet_system_loader.path
                       end
        # Path to the cached puppet files e.g. pluginsync
        @vardir_path = Puppet.settings[:vardir]

        @object_types = object_types
      end

      # Find all puppet related files, optionally from within a root path
      # @param from_root_path [String] The path which files can be found within.  If nil, only the default Puppet locations are searched e.g. vardir
      # @return [Array[String]] A list of all files that are found. This is the absolute path to the file.
      def find(from_root_path = nil)
        require 'tempfile'
        paths = []
        search_paths = @module_paths.nil? ? [] : @module_paths
        search_paths << @env_path unless @env_path.nil?
        search_paths << @vardir_path unless @vardir_path.nil?
        search_paths << @puppet_path unless @puppet_path.nil?

        searched_globs = []
        search_paths.each do |search_root|
          PuppetLanguageServerSidecar.log_message(:debug, "[PuppetPathFinder] Potential search root '#{search_root}'")
          next if search_root.nil?

          # We need absolute paths from here on in.
          search_root = File.expand_path(search_root)
          next unless path_in_root?(from_root_path, search_root) && Dir.exist?(search_root)

          PuppetLanguageServerSidecar.log_message(:debug, "[PuppetPathFinder] Using '#{search_root}' as a directory to search")
          # name of temp file to store the file type definitions (if any)
          @temp_file = Tempfile.new('file.rb')
          all_object_info.each do |object_type, paths_to_search|
            next unless object_types.include?(object_type)

            # TODO: next unless object_type is included
            paths_to_search.each do |path_info|
              path = File.join(search_root, path_info[:relative_dir])
              glob = path + path_info[:glob]
              next if searched_globs.include?(glob) # No point searching twice
              next unless Dir.exist?(path)

              searched_globs << glob
              PuppetLanguageServerSidecar.log_message(:debug, "[PuppetPathFinder] Searching glob '#{glob}''")

              Dir.glob(glob) do |filename|
                # if filename matches file.rb or /file/<any>.rb then we need to loop through each file type definition
                if filename.match?(%r{/type/file/.*.rb|/type/file.rb})
                  PuppetLanguageServerSidecar.log_message(:debug, "[PuppetPathFinder] Found file type definition at '#{filename}'.")
                  # Read each file type definition and write it to the temp file
                  @temp_file.write(File.read(filename))
                else
                  paths << filename
                end
              end
            end
          end
        end
        #  Add the temp_file.rb to the paths array for searching (if exists)
        if @temp_file && File.exist?(@temp_file.path)
          paths << @temp_file.path
          @temp_file.close
        end
        paths
      end

      private

      # Simple text based path checking
      # Is [path] in the [root]
      # @param root [String] The Root path
      # @param path [String] The path to check if it's within the root
      # @return [Boolean]
      def path_in_root?(root, path)
        # Doesn't matter what the root is, if the path is nil, it's false
        return false if path.nil?
        # Doesn't matter what the path is, if the root is nil it's true.
        return true if root.nil?
        # If the path is less than root, then it has to be false
        return false if root.length > path.length

        # Is the beginning of the path, the same as the root
        value = path.slice(0, root.length)
        value.casecmp(root).zero?
      end

      # The metadata for all object types and where they can be found on the filesystem
      # @return [Hash[Symbol => Hash[Symbol => String]]]
      def all_object_info
        {
          class: [
            { relative_dir: 'manifests',                   glob: '/**/*.pp' } # Pretty much everything in most modules
          ],
          datatype: [
            { relative_dir: 'lib/puppet/datatypes',        glob: '/**/*.rb' }, # Custom Data Types
            { relative_dir: 'types',                       glob: '/**/*.pp' }  # Data Type aliases
          ],
          function: [
            { relative_dir: 'functions',                   glob: '/**/*.pp' }, # Contains custom functions written in the Puppet language.
            { relative_dir: 'lib/puppet/functions',        glob: '/**/*.rb' }, # Contains functions written in Ruby for the modern Puppet::Functions API
            { relative_dir: 'lib/puppet/parser/functions', glob: '/**/*.rb' }  # Contains functions written in Ruby for the legacy Puppet::Parser::Functions API
          ],
          type: [
            { relative_dir: 'lib/puppet/type',             glob: '/{,file/}*.rb' } # Contains Puppet resource types. Resource types like `file` can live in subdirs, hence the glob
          ]
        }
      end
    end
  end
end
