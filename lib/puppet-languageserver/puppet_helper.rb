require 'puppet/indirector/face'
require 'pathname'

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

    def self.configure_cache(options = {})
      @inmemory_cache = PuppetLanguageServer::PuppetHelper::Cache.new(options)
      sidecar_queue.cache = @inmemory_cache
    end

    # Resource Face
    def self.resource_face_get_by_typename(typename)
      resources = Puppet::Face[:resource, '0.0.1'].search(typename)
      prune_resource_parameters(resources)
    end

    def self.resource_face_get_by_typename_and_title(typename, title)
      resources = Puppet::Face[:resource, '0.0.1'].find("#{typename}/#{title}")
      prune_resource_parameters(resources)
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

    def self.sidecar_queue
      @sidecar_queue_obj ||= PuppetLanguageServer::SidecarQueue.new
    end
    private_class_method :sidecar_queue

    def self.prune_resource_parameters(resources)
      # From https://github.com/puppetlabs/puppet/blob/488661d84e54904124514ab9e4500e81b10f84d1/lib/puppet/application/resource.rb#L146-L148
      if resources.is_a?(Array)
        resources.map(&:prune_parameters)
      else
        resources.prune_parameters
      end
    end
    private_class_method :prune_resource_parameters
  end
end
