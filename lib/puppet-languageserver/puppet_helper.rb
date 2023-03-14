# frozen_string_literal: true

require 'pathname'
require 'tempfile'
require 'puppet-languageserver/session_state/object_cache'
require 'puppet-languageserver/global_queues'

module PuppetLanguageServer
  module PuppetHelper
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

        args = ["--action-parameters=#{ap.to_json}"]
        args << "--local-workspace=#{local_workspace}" unless local_workspace.nil?

        sidecar_queue.execute('node_graph', args, false, session_state.connection_id)
      end
    end

    def self.get_puppet_resource(session_state, typename, title, local_workspace)
      ap = PuppetLanguageServer::Sidecar::Protocol::ActionParams.new
      ap['typename'] = typename
      ap['title'] = title unless title.nil?

      args = ["--action-parameters=#{ap.to_json}"]
      args << "--local-workspace=#{local_workspace}" unless local_workspace.nil?

      sidecar_queue.execute('resource_list', args, false, session_state.connection_id)
    end

    def self.get_type(session_state, name)
      session_state.object_cache.object_by_name(:type, name)
    end

    def self.type_names(session_state)
      session_state.object_cache.object_names_by_section(:type).map(&:to_s)
    end

    def self.function(session_state, name, tasks_mode = false)
      exclude_origins = tasks_mode ? [] : [:bolt]
      session_state.object_cache.object_by_name(
        :function,
        name,
        :fuzzy_match     => true,
        :exclude_origins => exclude_origins
      )
    end

    def self.function_names(session_state, tasks_mode = false)
      exclude_origins = tasks_mode ? [] : [:bolt]
      session_state.object_cache.object_names_by_section(:function, :exclude_origins => exclude_origins).map(&:to_s)
    end

    def self.get_class(session_state, name)
      session_state.object_cache.object_by_name(:class, name)
    end

    def self.class_names(session_state)
      session_state.object_cache.object_names_by_section(:class).map(&:to_s)
    end

    def self.datatype(session_state, name, tasks_mode = false)
      exclude_origins = tasks_mode ? [] : [:bolt]
      session_state.object_cache.object_by_name(
        :datatype,
        name,
        :fuzzy_match     => true,
        :exclude_origins => exclude_origins
      )
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
