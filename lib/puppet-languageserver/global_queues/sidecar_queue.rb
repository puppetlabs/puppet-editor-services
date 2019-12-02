# frozen_string_literal: true

require 'puppet-languageserver/global_queues/single_instance_queue'
require 'puppet_editor_services/server'
require 'open3'

module PuppetLanguageServer
  module GlobalQueues
    class SidecarQueueJob < SingleInstanceQueueJob
      attr_accessor :action
      attr_accessor :additional_args
      attr_accessor :handle_errors
      attr_accessor :connection_id

      def initialize(action, additional_args, handle_errors, connection_id)
        @action = action
        @additional_args = additional_args
        @handle_errors = handle_errors
        @connection_id = connection_id
      end

      def key
        "#{action}-#{connection_id}"
      end
    end

    # Module for enqueing and running sidecar jobs asynchronously
    # When adding a job, it will remove any other for the same
    # job in the queue, so that only the latest job needs to be processed.
    class SidecarQueue < SingleInstanceQueue
      def max_queue_threads
        2
      end

      def job_class
        SidecarQueueJob
      end

      def execute_job(job_object)
        super(job_object)
        connection = connection_from_connection_id(job_object.connection_id)
        raise "Connection is not available for connection id #{job_object.connection_id}" if connection.nil?
        sidecar_path = File.expand_path(File.join(__dir__, '..', '..', '..', 'puppet-languageserver-sidecar'))
        args = ['--action', job_object.action].concat(job_object.additional_args).concat(sidecar_args_from_connection(connection))
        cmd = ['ruby', sidecar_path].concat(args)
        PuppetLanguageServer.log_message(:debug, "SidecarQueue Thread: Running sidecar #{cmd}")
        stdout, stderr, status = run_sidecar(cmd)
        PuppetLanguageServer.log_message(:warning, "SidecarQueue Thread: Calling sidecar with #{args.join(' ')} returned exitcode #{status.exitstatus}, #{stderr}")
        return nil unless status.exitstatus.zero?

        # It's possible server has closed the connection while the sidecar is running.
        # So raise if the connection is no longer available
        raise "Connection is no longer available for connection id #{job_object.connection_id}" if connection_from_connection_id(job_object.connection_id).nil?
        session_state = session_state_from_connection(connection)
        raise "Session state is not available for connection id #{job_object.connection_id}" if session_state.nil?
        cache = session_state.object_cache

        # Correctly encode the result as UTF8
        result = stdout.bytes.pack('U*')

        case job_object.action.downcase
        when 'default_aggregate'
          lists = PuppetLanguageServer::Sidecar::Protocol::AggregateMetadata.new.from_json!(result)
          cache.import_sidecar_list!(lists.classes,   :class, :default)
          cache.import_sidecar_list!(lists.datatypes, :datatype, :default)
          cache.import_sidecar_list!(lists.functions, :function, :default)
          cache.import_sidecar_list!(lists.types,     :type, :default)

          PuppetLanguageServer::PuppetHelper.assert_default_classes_loaded
          PuppetLanguageServer::PuppetHelper.assert_default_functions_loaded
          PuppetLanguageServer::PuppetHelper.assert_default_types_loaded
          PuppetLanguageServer::PuppetHelper.assert_default_datatypes_loaded

          lists.each_list do |k, v|
            if v.nil?
              PuppetLanguageServer.log_message(:debug, "SidecarQueue Thread: default_aggregate returned no #{k}")
            else
              PuppetLanguageServer.log_message(:debug, "SidecarQueue Thread: default_aggregate returned #{v.count} #{k}")
            end
          end

        when 'default_classes'
          list = PuppetLanguageServer::Sidecar::Protocol::PuppetClassList.new.from_json!(result)
          cache.import_sidecar_list!(list, :class, :default)
          PuppetLanguageServer.log_message(:debug, "SidecarQueue Thread: default_classes returned #{list.count} items")

          PuppetLanguageServer::PuppetHelper.assert_default_classes_loaded

        when 'default_datatypes'
          list = PuppetLanguageServer::Sidecar::Protocol::PuppetDataTypeList.new.from_json!(result)
          cache.import_sidecar_list!(list, :datatype, :default)
          PuppetLanguageServer.log_message(:debug, "SidecarQueue Thread: default_datatypes returned #{list.count} items")

          PuppetLanguageServer::PuppetHelper.assert_default_datatypes_loaded

        when 'default_functions'
          list = PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionList.new.from_json!(result)
          cache.import_sidecar_list!(list, :function, :default)
          PuppetLanguageServer.log_message(:debug, "SidecarQueue Thread: default_functions returned #{list.count} items")

          PuppetLanguageServer::PuppetHelper.assert_default_functions_loaded

        when 'default_types'
          list = PuppetLanguageServer::Sidecar::Protocol::PuppetTypeList.new.from_json!(result)
          cache.import_sidecar_list!(list, :type, :default)
          PuppetLanguageServer.log_message(:debug, "SidecarQueue Thread: default_types returned #{list.count} items")

          PuppetLanguageServer::PuppetHelper.assert_default_types_loaded

        when 'facts'
          list = PuppetLanguageServer::Sidecar::Protocol::FactList.new.from_json!(result)
          cache.import_sidecar_list!(list, :fact, :default)
          PuppetLanguageServer.log_message(:debug, "SidecarQueue Thread: facts returned #{list.count} items")

          PuppetLanguageServer::FacterHelper.assert_facts_loaded

        when 'node_graph'
          return PuppetLanguageServer::Sidecar::Protocol::PuppetNodeGraph.new.from_json!(result)

        when 'resource_list'
          return PuppetLanguageServer::Sidecar::Protocol::ResourceList.new.from_json!(result)

        when 'workspace_aggregate'
          lists = PuppetLanguageServer::Sidecar::Protocol::AggregateMetadata.new.from_json!(result)
          cache.import_sidecar_list!(lists.classes,   :class, :workspace)
          cache.import_sidecar_list!(lists.datatypes, :datatype, :workspace)
          cache.import_sidecar_list!(lists.functions, :function, :workspace)
          cache.import_sidecar_list!(lists.types,     :type, :workspace)

          lists.each_list do |k, v|
            if v.nil?
              PuppetLanguageServer.log_message(:debug, "SidecarQueue Thread: workspace_aggregate returned no #{k}")
            else
              PuppetLanguageServer.log_message(:debug, "SidecarQueue Thread: workspace_aggregate returned #{v.count} #{k}")
            end
          end

        when 'workspace_classes'
          list = PuppetLanguageServer::Sidecar::Protocol::PuppetClassList.new.from_json!(result)
          cache.import_sidecar_list!(list, :class, :workspace)
          PuppetLanguageServer.log_message(:debug, "SidecarQueue Thread: workspace_classes returned #{list.count} items")

        when 'workspace_datatypes'
          list = PuppetLanguageServer::Sidecar::Protocol::PuppetDataTypeList.new.from_json!(result)
          cache.import_sidecar_list!(list, :datatype, :workspace)
          PuppetLanguageServer.log_message(:debug, "SidecarQueue Thread: workspace_datatypes returned #{list.count} items")

        when 'workspace_functions'
          list = PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionList.new.from_json!(result)
          cache.import_sidecar_list!(list, :function, :workspace)
          PuppetLanguageServer.log_message(:debug, "SidecarQueue Thread: workspace_functions returned #{list.count} items")

        when 'workspace_types'
          list = PuppetLanguageServer::Sidecar::Protocol::PuppetTypeList.new.from_json!(result)
          cache.import_sidecar_list!(list, :type, :workspace)
          PuppetLanguageServer.log_message(:debug, "SidecarQueue Thread: workspace_types returned #{list.count} items")

        else
          PuppetLanguageServer.log_message(:error, "SidecarQueue Thread: Unknown action #{job_object.action}")
        end

        true
      rescue StandardError => e
        raise unless job_object.handle_errors
        PuppetLanguageServer.log_message(:error, "SidecarQueue Thread: Error running action #{job_object.action}. #{e}")
        nil
      end

      private

      def connection_from_connection_id(connection_id)
        PuppetEditorServices::Server.current_server.connection(connection_id)
      end

      def session_state_from_connection(connection)
        return if connection.nil?
        handler = connection.protocol.handler
        handler.respond_to?(:session_state) ? handler.session_state : nil
      end

      def run_sidecar(cmd)
        Open3.capture3(*cmd)
      end

      def sidecar_args_from_connection(connection)
        return nil if connection.nil?
        options = connection.server.handler_options
        return [] if options.nil?
        result = []
        result << '--no-cache' if options[:disable_sidecar_cache]
        result << "--puppet-version=#{Puppet.version}"
        result << "--feature-flags=#{options[:flags].join(',')}" if options[:flags] && !options[:flags].empty?
        result << "--puppet-settings=#{options[:puppet_settings].join(',')}" if options[:puppet_settings] && !options[:puppet_settings].empty?
        result
      end
    end
  end
end
