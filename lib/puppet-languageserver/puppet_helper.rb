# frozen_string_literal: true

require 'pathname'
require 'tempfile'
require 'puppet-languageserver/session_state/object_cache'
require 'puppet-languageserver/global_queues'

module PuppetLanguageServer
  module PuppetHelper
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
    def self.get_node_graph(session_state, content, local_workspace)
      with_temporary_file(content) do |filepath|
        ap = PuppetLanguageServer::Sidecar::Protocol::ActionParams.new
        ap['source'] = filepath

        args = ['--action-parameters=' + ap.to_json]
        args << "--local-workspace=#{local_workspace}" unless local_workspace.nil?

        sidecar_queue.execute('node_graph', args, false, session_state.connection_id)
      end
    end

    def self.get_puppet_resource(session_state, typename, title, local_workspace)
      ap = PuppetLanguageServer::Sidecar::Protocol::ActionParams.new
      ap['typename'] = typename
      ap['title'] = title unless title.nil?

      args = ['--action-parameters=' + ap.to_json]
      args << "--local-workspace=#{local_workspace}" unless local_workspace.nil?

      sidecar_queue.execute('resource_list', args, false, session_state.connection_id)
    end

    def self.get_type(name)
      @inmemory_cache.object_by_name(:type, name)
    end

    def self.type_names
      @inmemory_cache.object_names_by_section(:type).map(&:to_s)
    end

    def self.filtered_function_names(&block)
      result = []
      @inmemory_cache.objects_by_section(:function) do |name, data|
        filter = block.call(name, data)
        result << name if filter == true
      end
      result
    end

    def self.function(name, tasks_mode = false)
      exclude_origins = tasks_mode ? [] : [:bolt]
      @inmemory_cache.object_by_name(
        :function,
        name,
        :fuzzy_match     => true,
        :exclude_origins => exclude_origins
      )
    end

    def self.function_names(tasks_mode = false)
      exclude_origins = tasks_mode ? [] : [:bolt]
      @inmemory_cache.object_names_by_section(:function, :exclude_origins => exclude_origins).map(&:to_s)
    end

    def self.get_class(name)
      @inmemory_cache.object_by_name(:class, name)
    end

    def self.class_names
      @inmemory_cache.object_names_by_section(:class).map(&:to_s)
    end

    def self.datatype(name, tasks_mode = false)
      exclude_origins = tasks_mode ? [] : [:bolt]
      @inmemory_cache.object_by_name(
        :datatype,
        name,
        :fuzzy_match     => true,
        :exclude_origins => exclude_origins
      )
    end

    # Only required during refactoring of PuppetHelper to use the session state.
    # Once the refactor is complete this method is no longer required.
    def self.cache
      raise('Puppet Helper Cache has not been configured') if @inmemory_cache.nil?
      @inmemory_cache
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
  end
end
