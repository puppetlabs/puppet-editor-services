# frozen_string_literal: true

require 'pathname'
require 'tempfile'
require 'puppet-languageserver/session_state/object_cache'
require 'puppet-languageserver/global_queues'

module PuppetLanguageServer
  module PuppetHelper
    # Reference - https://github.com/puppetlabs/puppet/blob/master/lib/puppet/reference/type.rb

    @default_types_loaded = nil
    @default_functions_loaded = nil
    @default_classes_loaded = nil
    @inmemory_cache = nil

    def self.initialize_helper(_options)
      @inmemory_cache = PuppetLanguageServer::SessionState::ObjectCache.new
    end

    def self.module_path
      return @module_path unless @module_path.nil?
      # TODO: It would be nice if this wasn't using the whole puppet environment to calculate the modulepath directoties
      # In the meantime memoize it. Currently you can't change the modulepath mid-process.
      begin
        env = Puppet.lookup(:environments).get!(Puppet.settings[:environment])
      rescue Puppet::Environments::EnvironmentNotFound, StandardError
        env = Puppet.lookup(:current_environment)
      end
      return [] if env.nil?
      @module_path = env.modulepath
    end

    # Node Graph
    def self.get_node_graph(content, local_workspace)
      with_temporary_file(content) do |filepath|
        ap = PuppetLanguageServer::Sidecar::Protocol::ActionParams.new
        ap['source'] = filepath

        args = ['--action-parameters=' + ap.to_json]
        args << "--local-workspace=#{local_workspace}" unless local_workspace.nil?

        sidecar_queue.execute('node_graph', args, false, connection_id)
      end
    end

    def self.get_puppet_resource(typename, title, local_workspace)
      ap = PuppetLanguageServer::Sidecar::Protocol::ActionParams.new
      ap['typename'] = typename
      ap['title'] = title unless title.nil?

      args = ['--action-parameters=' + ap.to_json]
      args << "--local-workspace=#{local_workspace}" unless local_workspace.nil?

      sidecar_queue.execute('resource_list', args, false, connection_id)
    end

    # Static data
    def self.static_data_loaded?
      @static_data_loaded.nil? ? false : @static_data_loaded
    end

    def self.load_static_data
      raise('Puppet Helper Cache has not been configured') if @inmemory_cache.nil?
      @static_data_loaded = false

      bolt_static_data = PuppetLanguageServer::Sidecar::Protocol::AggregateMetadata.new
      Dir.glob(File.join(PuppetLanguageServer.static_data_dir, 'bolt-*.json')) do |path|
        PuppetLanguageServer.log_message(:debug, "Importing static data file #{path}...")
        # No need to catch errors here. As this is static data and is tested in rspec
        # Sure, we could have corrupt/missing files on disk, but then we have bigger issues
        data = PuppetLanguageServer::Sidecar::Protocol::AggregateMetadata.new.from_json!(File.open(path, 'rb:UTF-8') { |f| f.read })
        data.each_list { |_, list| bolt_static_data.concat!(list) }
      end

      @inmemory_cache.import_sidecar_list!(bolt_static_data.classes,   :class,    :bolt)
      @inmemory_cache.import_sidecar_list!(bolt_static_data.datatypes, :datatype, :bolt)
      @inmemory_cache.import_sidecar_list!(bolt_static_data.functions, :function, :bolt)
      @inmemory_cache.import_sidecar_list!(bolt_static_data.types,     :type,     :bolt)

      bolt_static_data.each_list do |k, v|
        if v.nil?
          PuppetLanguageServer.log_message(:debug, "Static bolt data returned no #{k}")
        else
          PuppetLanguageServer.log_message(:debug, "Static bolt data returned #{v.count} #{k}")
        end
      end

      @static_data_loaded = true
    end

    def self.load_static_data_async
      raise('Puppet Helper Cache has not been configured') if @inmemory_cache.nil?
      @static_data_loaded = false
      Thread.new do
        load_static_data
      end
    end

    # Types
    def self.default_types_loaded?
      @default_types_loaded.nil? ? false : @default_types_loaded
    end

    def self.assert_default_types_loaded
      @default_types_loaded = true
    end

    def self.load_default_types
      raise('Puppet Helper Cache has not been configured') if @inmemory_cache.nil?
      @default_types_loaded = false
      sidecar_queue.execute('default_types', [], false, connection_id)
    end

    def self.load_default_types_async
      raise('Puppet Helper Cache has not been configured') if @inmemory_cache.nil?
      @default_types_loaded = false
      sidecar_queue.enqueue('default_types', [], false, connection_id)
    end

    def self.get_type(name)
      return nil if @default_types_loaded == false
      raise('Puppet Helper Cache has not been configured') if @inmemory_cache.nil?
      @inmemory_cache.object_by_name(:type, name)
    end

    def self.type_names
      return [] if @default_types_loaded == false
      raise('Puppet Helper Cache has not been configured') if @inmemory_cache.nil?
      @inmemory_cache.object_names_by_section(:type).map(&:to_s)
    end

    # Functions
    def self.default_functions_loaded?
      @default_functions_loaded.nil? ? false : @default_functions_loaded
    end

    def self.assert_default_functions_loaded
      @default_functions_loaded = true
    end

    def self.load_default_functions
      raise('Puppet Helper Cache has not been configured') if @inmemory_cache.nil?
      @default_functions_loaded = false
      sidecar_queue.execute('default_functions', [], false, connection_id)
    end

    def self.load_default_functions_async
      raise('Puppet Helper Cache has not been configured') if @inmemory_cache.nil?
      @default_functions_loaded = false
      sidecar_queue.enqueue('default_functions', [], false, connection_id)
    end

    def self.filtered_function_names(&block)
      return [] if @default_functions_loaded == false
      raise('Puppet Helper Cache has not been configured') if @inmemory_cache.nil?
      load_default_functions if @default_functions_loaded.nil?
      result = []
      @inmemory_cache.objects_by_section(:function) do |name, data|
        filter = block.call(name, data)
        result << name if filter == true
      end
      result
    end

    def self.function(name, tasks_mode = false)
      return nil if @default_functions_loaded == false
      raise('Puppet Helper Cache has not been configured') if @inmemory_cache.nil?
      load_default_functions unless @default_functions_loaded
      exclude_origins = tasks_mode ? [] : [:bolt]
      @inmemory_cache.object_by_name(
        :function,
        name,
        :fuzzy_match     => true,
        :exclude_origins => exclude_origins
      )
    end

    def self.function_names(tasks_mode = false)
      return [] if @default_functions_loaded == false
      raise('Puppet Helper Cache has not been configured') if @inmemory_cache.nil?
      load_default_functions if @default_functions_loaded.nil?
      exclude_origins = tasks_mode ? [] : [:bolt]
      @inmemory_cache.object_names_by_section(:function, :exclude_origins => exclude_origins).map(&:to_s)
    end

    # Classes and Defined Types
    def self.default_classes_loaded?
      @default_classes_loaded.nil? ? false : @default_classes_loaded
    end

    def self.assert_default_classes_loaded
      @default_classes_loaded = true
    end

    def self.load_default_classes
      raise('Puppet Helper Cache has not been configured') if @inmemory_cache.nil?
      @default_classes_loaded = false
      sidecar_queue.execute('default_classes', [], false, connection_id)
    end

    def self.load_default_classes_async
      raise('Puppet Helper Cache has not been configured') if @inmemory_cache.nil?
      @default_classes_loaded = false
      sidecar_queue.enqueue('default_classes', [], false, connection_id)
    end

    def self.get_class(name)
      return nil if @default_classes_loaded == false
      raise('Puppet Helper Cache has not been configured') if @inmemory_cache.nil?
      @inmemory_cache.object_by_name(:class, name)
    end

    def self.class_names
      return [] if @default_classes_loaded == false
      raise('Puppet Helper Cache has not been configured') if @inmemory_cache.nil?
      load_default_classes if @default_classes_loaded.nil?
      @inmemory_cache.object_names_by_section(:class).map(&:to_s)
    end

    # DataTypes
    def self.default_datatypes_loaded?
      @default_datatypes_loaded.nil? ? false : @default_datatypes_loaded
    end

    def self.assert_default_datatypes_loaded
      @default_datatypes_loaded = true
    end

    def self.load_default_datatypes
      raise('Puppet Helper Cache has not been configured') if @inmemory_cache.nil?
      @default_datatypes_loaded = false
      sidecar_queue.execute('default_datatypes', [], false, connection_id)
    end

    def self.load_default_datatypes_async
      raise('Puppet Helper Cache has not been configured') if @inmemory_cache.nil?
      @default_datatypes_loaded = false
      sidecar_queue.enqueue('default_datatypes', [], false, connection_id)
    end

    def self.datatype(name, tasks_mode = false)
      return nil if @default_datatypes_loaded == false
      raise('Puppet Helper Cache has not been configured') if @inmemory_cache.nil?
      load_default_datatypes unless @default_datatypes_loaded
      load_static_data if tasks_mode && !static_data_loaded?
      exclude_origins = tasks_mode ? [] : [:bolt]
      @inmemory_cache.object_by_name(
        :datatype,
        name,
        :fuzzy_match     => true,
        :exclude_origins => exclude_origins
      )
    end

    def self.cache
      raise('Puppet Helper Cache has not been configured') if @inmemory_cache.nil?
      @inmemory_cache
    end

    # This is a temporary module level variable.  It will be removed once PuppetHelper
    # is refactored into a session_state style class
    def self.connection_id
      @connection_id
    end

    # This is a temporary module level variable.  It will be removed once PuppetHelper
    # is refactored into a session_state style class
    def self.connection_id=(value)
      @connection_id = value
    end

    # Workspace Loading
    def self.load_workspace_async
      if PuppetLanguageServer.featureflag?('puppetstrings')
        return true if PuppetLanguageServer::DocumentStore.store_root_path.nil?
        sidecar_queue.enqueue('workspace_aggregate', ['--local-workspace', PuppetLanguageServer::DocumentStore.store_root_path], false, connection_id)
        return true
      end
      load_workspace_classes_async
      load_workspace_functions_async
      load_workspace_types_async
      true
    end

    def self.load_workspace_classes_async
      return if PuppetLanguageServer::DocumentStore.store_root_path.nil?
      sidecar_queue.enqueue('workspace_classes', ['--local-workspace', PuppetLanguageServer::DocumentStore.store_root_path], false, connection_id)
    end

    def self.load_workspace_functions_async
      return if PuppetLanguageServer::DocumentStore.store_root_path.nil?
      sidecar_queue.enqueue('workspace_functions', ['--local-workspace', PuppetLanguageServer::DocumentStore.store_root_path], false, connection_id)
    end

    def self.load_workspace_types_async
      return if PuppetLanguageServer::DocumentStore.store_root_path.nil?
      sidecar_queue.enqueue('workspace_types', ['--local-workspace', PuppetLanguageServer::DocumentStore.store_root_path], false, connection_id)
    end

    def self.purge_workspace
      PuppetLanguageServer::PuppetHelper.cache.import_sidecar_list!([], :class, :workspace)
      PuppetLanguageServer::PuppetHelper.cache.import_sidecar_list!([], :function, :workspace)
      PuppetLanguageServer::PuppetHelper.cache.import_sidecar_list!([], :type, :workspace)
    end

    def self.sidecar_queue
      PuppetLanguageServer::GlobalQueues.sidecar_queue
    end

    def self.with_temporary_file(content)
      tempfile = Tempfile.new('langserver-sidecar')
      tempfile.open

      tempfile.write(content)

      tempfile.close

      yield tempfile.path
    ensure
      tempfile.delete if tempfile
    end
    private_class_method :with_temporary_file

    def self.load_default_aggregate_async
      @default_classes_loaded   = false if @default_classes_loaded.nil?
      @default_functions_loaded = false if @default_functions_loaded.nil?
      @default_types_loaded     = false if @default_types_loaded.nil?
      sidecar_queue.enqueue('default_aggregate', [], false, connection_id)
    end
  end
end
