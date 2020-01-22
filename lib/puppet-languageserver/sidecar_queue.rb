# frozen_string_literal: true

require 'open3'

module PuppetLanguageServer
  # Module for enqueing and running sidecar jobs asynchronously
  # When adding a job, it will remove any other for the same
  # job in the queue, so that only the latest job needs to be processed.
  class SidecarQueue
    attr_writer :cache

    def initialize(options = {})
      @queue = []
      @queue_mutex = Mutex.new
      @queue_threads_mutex = Mutex.new
      @queue_threads = []
      @cache = nil
      @queue_options = options
    end

    def queue_size
      2
    end

    # Enqueue a sidecar action
    def enqueue(action, additional_args)
      @queue_mutex.synchronize do
        @queue.reject! { |item| item[:action] == action }
        @queue << { action: action, additional_args: additional_args }
      end

      @queue_threads_mutex.synchronize do
        # Clear up any done threads
        @queue_threads.reject! { |item| item.nil? || !item.alive? }
        # Append a new thread if we have space
        if @queue_threads.count < queue_size
          @queue_threads << Thread.new do
            begin
              worker
            rescue => e # rubocop:disable Style/RescueStandardError
              PuppetLanguageServer.log_message(:error, "Error in SidecarQueue Thread: #{e}")
              raise
            end
          end
        end
      end
      nil
    end

    # Synchronously call the sidecar
    # Returns nil if an error occurs, otherwise returns an object
    def execute_sync(action, additional_args, handle_errors = false)
      return nil if @cache.nil?
      sidecar_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'puppet-languageserver-sidecar'))
      args = ['--action', action].concat(additional_args).concat(sidecar_args_from_options)

      cmd = ['ruby', sidecar_path].concat(args)
      PuppetLanguageServer.log_message(:debug, "SidecarQueue Thread: Running sidecar #{cmd}")
      stdout, stderr, status = run_sidecar(cmd)
      PuppetLanguageServer.log_message(:warning, "SidecarQueue Thread: Calling sidecar with #{args.join(' ')} returned exitcode #{status.exitstatus}, #{stderr}")
      return nil unless status.exitstatus.zero?
      # Correctly encode the result as UTF8
      result = stdout.bytes.pack('U*')

      case action.downcase
      when 'default_aggregate'
        lists = PuppetLanguageServer::Sidecar::Protocol::AggregateMetadata.new.from_json!(result)
        @cache.import_sidecar_list!(lists.classes,   :class, :default)
        @cache.import_sidecar_list!(lists.datatypes, :datatype, :default)
        @cache.import_sidecar_list!(lists.functions, :function, :default)
        @cache.import_sidecar_list!(lists.types,     :type, :default)

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
        @cache.import_sidecar_list!(list, :class, :default)
        PuppetLanguageServer.log_message(:debug, "SidecarQueue Thread: default_classes returned #{list.count} items")

        PuppetLanguageServer::PuppetHelper.assert_default_classes_loaded

      when 'default_datatypes'
        list = PuppetLanguageServer::Sidecar::Protocol::PuppetDataTypeList.new.from_json!(result)
        @cache.import_sidecar_list!(list, :datatype, :default)
        PuppetLanguageServer.log_message(:debug, "SidecarQueue Thread: default_datatypes returned #{list.count} items")

        PuppetLanguageServer::PuppetHelper.assert_default_datatypes_loaded

      when 'default_functions'
        list = PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionList.new.from_json!(result)
        @cache.import_sidecar_list!(list, :function, :default)
        PuppetLanguageServer.log_message(:debug, "SidecarQueue Thread: default_functions returned #{list.count} items")

        PuppetLanguageServer::PuppetHelper.assert_default_functions_loaded

      when 'default_types'
        list = PuppetLanguageServer::Sidecar::Protocol::PuppetTypeList.new.from_json!(result)
        @cache.import_sidecar_list!(list, :type, :default)
        PuppetLanguageServer.log_message(:debug, "SidecarQueue Thread: default_types returned #{list.count} items")

        PuppetLanguageServer::PuppetHelper.assert_default_types_loaded

      when 'facts'
        list = PuppetLanguageServer::Sidecar::Protocol::FactList.new.from_json!(result)
        @cache.import_sidecar_list!(list, :fact, :default)
        PuppetLanguageServer.log_message(:debug, "SidecarQueue Thread: facts returned #{list.count} items")

        PuppetLanguageServer::FacterHelper.assert_facts_loaded

      when 'node_graph'
        return PuppetLanguageServer::Sidecar::Protocol::NodeGraph.new.from_json!(result)

      when 'resource_list'
        return PuppetLanguageServer::Sidecar::Protocol::ResourceList.new.from_json!(result)

      when 'workspace_aggregate'
        lists = PuppetLanguageServer::Sidecar::Protocol::AggregateMetadata.new.from_json!(result)
        @cache.import_sidecar_list!(lists.classes,   :class, :workspace)
        @cache.import_sidecar_list!(lists.datatypes, :datatype, :workspace)
        @cache.import_sidecar_list!(lists.functions, :function, :workspace)
        @cache.import_sidecar_list!(lists.types,     :type, :workspace)

        lists.each_list do |k, v|
          if v.nil?
            PuppetLanguageServer.log_message(:debug, "SidecarQueue Thread: workspace_aggregate returned no #{k}")
          else
            PuppetLanguageServer.log_message(:debug, "SidecarQueue Thread: workspace_aggregate returned #{v.count} #{k}")
          end
        end

      when 'workspace_classes'
        list = PuppetLanguageServer::Sidecar::Protocol::PuppetClassList.new.from_json!(result)
        @cache.import_sidecar_list!(list, :class, :workspace)
        PuppetLanguageServer.log_message(:debug, "SidecarQueue Thread: workspace_classes returned #{list.count} items")

      when 'workspace_datatypes'
        list = PuppetLanguageServer::Sidecar::Protocol::PuppetDataTypeList.new.from_json!(result)
        @cache.import_sidecar_list!(list, :datatype, :workspace)
        PuppetLanguageServer.log_message(:debug, "SidecarQueue Thread: workspace_datatypes returned #{list.count} items")

      when 'workspace_functions'
        list = PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionList.new.from_json!(result)
        @cache.import_sidecar_list!(list, :function, :workspace)
        PuppetLanguageServer.log_message(:debug, "SidecarQueue Thread: workspace_functions returned #{list.count} items")

      when 'workspace_types'
        list = PuppetLanguageServer::Sidecar::Protocol::PuppetTypeList.new.from_json!(result)
        @cache.import_sidecar_list!(list, :type, :workspace)
        PuppetLanguageServer.log_message(:debug, "SidecarQueue Thread: workspace_types returned #{list.count} items")

      else
        PuppetLanguageServer.log_message(:error, "SidecarQueue Thread: Unknown action action #{action}")
      end

      true
    rescue StandardError => e
      raise unless handle_errors
      PuppetLanguageServer.log_message(:error, "SidecarQueue Thread: Error running action #{action}. #{e}")
      nil
    end

    # Wait for the queue to become empty
    def drain_queue
      @queue_threads.each do |item|
        item.join unless item.nil? || !item.alive?
      end
      nil
    end

    # Testing helper resets the queue and prepopulates it with
    # a known arbitrary configuration.
    # ONLY USE THIS FOR TESTING!
    def reset_queue(initial_state = [])
      @queue_mutex.synchronize do
        @queue = initial_state
      end
    end

    private

    # Thread worker which processes all jobs in the queue and calls the sidecar for each action
    def worker
      work_item = nil
      loop do
        @queue_mutex.synchronize do
          return if @queue.empty?
          work_item = @queue.shift
        end
        return if work_item.nil?

        action          = work_item[:action]
        additional_args = work_item[:additional_args]

        # Perform action
        _result = execute_sync(action, additional_args)
      end
    end

    def run_sidecar(cmd)
      Open3.capture3(*cmd)
    end

    def sidecar_args_from_options
      return [] if @queue_options.nil?
      result = []
      result << '--no-cache' if @queue_options[:disable_sidecar_cache]
      result << "--puppet-version=#{Puppet.version}"
      result << "--feature-flags=#{@queue_options[:flags].join(',')}" if @queue_options[:flags] && !@queue_options[:flags].empty?
      result << "--puppet-settings=#{@queue_options[:puppet_settings].join(',')}" if @queue_options[:puppet_settings] && !@queue_options[:puppet_settings].empty?
      result
    end
  end
end
