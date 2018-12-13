require 'pathname'
require 'tempfile'

%w[puppet_helper/cache_objects puppet_helper/cache].each do |lib|
  begin
    require "puppet-languageserver/#{lib}"
  rescue LoadError
    require File.expand_path(File.join(File.dirname(__FILE__), lib))
  end
end

module PuppetLanguageServer
  module PuppetHelper
    # Reference - https://github.com/puppetlabs/puppet/blob/master/lib/puppet/reference/type.rb

    @default_types_loaded = nil
    @default_functions_loaded = nil
    @default_classes_loaded = nil
    @inmemory_cache = nil
    @sidecar_queue_obj = nil
    @helper_options = nil

    def self.initialize_helper(options = {})
      @helper_options = options
      @inmemory_cache = PuppetLanguageServer::PuppetHelper::Cache.new
      sidecar_queue.cache = @inmemory_cache
    end

    def self.all_objects(&_block)
      return nil if @default_types_loaded == false
      raise('Puppet Helper Cache has not been configured') if @inmemory_cache.nil?
      @inmemory_cache.all_objects do |key, item|
        yield key, item
      end
    end

    # Node Graph
    def self.get_node_graph(content, local_workspace)
      with_temporary_file(content) do |filepath|
        ap = PuppetLanguageServer::Sidecar::Protocol::ActionParams.new
        ap['source'] = filepath

        args = ['--action-parameters=' + ap.to_json]
        args << "--local-workspace=#{local_workspace}" unless local_workspace.nil?

        sidecar_queue.execute_sync('node_graph', args, false)
      end
    end

    def self.get_puppet_resource(typename, title, local_workspace)
      ap = PuppetLanguageServer::Sidecar::Protocol::ActionParams.new
      ap['typename'] = typename
      ap['title'] = title unless title.nil?

      args = ['--action-parameters=' + ap.to_json]
      args << "--local-workspace=#{local_workspace}" unless local_workspace.nil?

      sidecar_queue.execute_sync('resource_list', args)
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
      sidecar_queue.execute_sync('default_types', [])
    end

    def self.load_default_types_async
      raise('Puppet Helper Cache has not been configured') if @inmemory_cache.nil?
      @default_types_loaded = false
      sidecar_queue.enqueue('default_types', [])
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
      sidecar_queue.execute_sync('default_functions', [])
    end

    def self.load_default_functions_async
      raise('Puppet Helper Cache has not been configured') if @inmemory_cache.nil?
      @default_functions_loaded = false
      sidecar_queue.enqueue('default_functions', [])
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

    def self.function(name)
      return nil if @default_functions_loaded == false
      raise('Puppet Helper Cache has not been configured') if @inmemory_cache.nil?
      load_default_functions unless @default_functions_loaded
      @inmemory_cache.object_by_name(:function, name)
    end

    def self.function_names
      return [] if @default_functions_loaded == false
      raise('Puppet Helper Cache has not been configured') if @inmemory_cache.nil?
      load_default_functions if @default_functions_loaded.nil?
      @inmemory_cache.object_names_by_section(:function).map(&:to_s)
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
      sidecar_queue.execute_sync('default_classes', [])
    end

    def self.load_default_classes_async
      raise('Puppet Helper Cache has not been configured') if @inmemory_cache.nil?
      @default_classes_loaded = false
      sidecar_queue.enqueue('default_classes', [])
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

    # The object cache.  Note this should only be used for testing
    def self.cache
      @inmemory_cache
    end

    # Workspace Loading
    def self.load_workspace_async
      load_workspace_classes_async
      load_workspace_functions_async
      load_workspace_types_async
      true
    end

    def self.load_workspace_classes_async
      return if PuppetLanguageServer::DocumentStore.store_root_path.nil?
      sidecar_queue.enqueue('workspace_classes', ['--local-workspace', PuppetLanguageServer::DocumentStore.store_root_path])
    end

    def self.load_workspace_functions_async
      return if PuppetLanguageServer::DocumentStore.store_root_path.nil?
      sidecar_queue.enqueue('workspace_functions', ['--local-workspace', PuppetLanguageServer::DocumentStore.store_root_path])
    end

    def self.load_workspace_types_async
      return if PuppetLanguageServer::DocumentStore.store_root_path.nil?
      sidecar_queue.enqueue('workspace_types', ['--local-workspace', PuppetLanguageServer::DocumentStore.store_root_path])
    end

    def self.purge_workspace
      PuppetLanguageServer::PuppetHelper.cache.import_sidecar_list!([], :class, :workspace)
      PuppetLanguageServer::PuppetHelper.cache.import_sidecar_list!([], :function, :workspace)
      PuppetLanguageServer::PuppetHelper.cache.import_sidecar_list!([], :type, :workspace)
    end

    def self.sidecar_queue
      @sidecar_queue_obj ||= PuppetLanguageServer::SidecarQueue.new(@helper_options)
    end
    private_class_method :sidecar_queue

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
  end
end
