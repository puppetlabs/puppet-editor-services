# frozen_string_literal: true

require 'dsp/dsp'
require 'puppet_editor_services'

require 'optparse'
require 'logger'

module PuppetDebugServer
  def self.version
    PuppetEditorServices.version
  end

  def self.require_gems(options)
    original_verbose = $VERBOSE
    $VERBOSE = nil

    # Use specific Puppet Gem version if possible
    # Note that puppet is required implicitly in the monkey patches
    # so we don't need to explicity require it here
    unless options[:puppet_version].nil?
      available_puppet_gems = Gem::Specification
                              .select { |item| item.name.casecmp('puppet').zero? }
                              .map { |item| item.version.to_s }
      if available_puppet_gems.include?(options[:puppet_version])
        gem 'puppet', options[:puppet_version]
      else
        log_message(:warn, "Unable to use puppet version #{options[:puppet_version]}, as only the following versions are available [#{available_puppet_gems.join(', ')}]")
      end
    end

    %w[
      message_handler
      hooks
      puppet_debug_session
      debug_session/break_points
      debug_session/hook_handlers
      debug_session/flow_control
      debug_session/puppet_session_run_mode
      debug_session/puppet_session_state
      puppet_monkey_patches
    ].each do |lib|
      begin
        require "puppet-debugserver/#{lib}"
      rescue LoadError
        require File.expand_path(File.join(File.dirname(__FILE__), 'puppet-debugserver', lib))
      end
    end
  ensure
    $VERBOSE = original_verbose
  end

  class CommandLineParser
    def self.parse(options)
      # Set defaults here
      args = {
        port: nil,
        ipaddress: 'localhost',
        stop_on_client_exit: true,
        connection_timeout: 10,
        debug: nil,
        puppet_version: nil
      }

      opt_parser = OptionParser.new do |opts|
        opts.banner = 'Usage: puppet-debugserver.rb [options]'

        opts.on('-pPORT', '--port=PORT', 'TCP Port to listen on.  Default is random port') do |port|
          args[:port] = port.to_i
        end

        opts.on('-ipADDRESS', '--ip=ADDRESS', "IP Address to listen on (0.0.0.0 for all interfaces).  Default is #{args[:ipaddress]}") do |ipaddress|
          args[:ipaddress] = ipaddress
        end

        opts.on('-tTIMEOUT', '--timeout=TIMEOUT', "Stop the Debug Server if a client does not connection within TIMEOUT seconds.  A value of zero will not timeout.  Default is #{args[:connection_timeout]} seconds") do |timeout|
          args[:connection_timeout] = timeout.to_i
        end

        opts.on('--debug=DEBUG', "Output debug information.  Either specify a filename or 'STDOUT'.  Default is no debug output") do |debug|
          args[:debug] = debug
        end

        opts.on('--puppet-version=TEXT', String, 'The version of the Puppet Gem to use (defaults to latest version if not specified or the version does not exist) e.g. --puppet-version=5.4.0') do |text|
          args[:puppet_version] = text
        end

        opts.on('-h', '--help', 'Prints this help') do
          puts opts
          exit
        end

        opts.on('-v', '--version', 'Prints the Debug Server version') do
          puts PuppetEditorServices.version
          exit
        end
      end

      opt_parser.parse!(options.dup)
      args
    end
  end

  def self.log_message(severity, message)
    PuppetEditorServices.log_message(severity, message)
  end

  def self.init_puppet(options)
    PuppetEditorServices.init_logging(options)
    log_message(:info, "Debug Server is v#{PuppetDebugServer.version}")
    log_message(:debug, 'Loading gems...')
    require_gems(options)
    require 'puppet'
    log_message(:info, "Using Puppet v#{::Puppet.version}")

    true
  end

  def self.rpc_server_async(options)
    log_message(:info, 'Starting RPC Server (Async)...')

    Thread.new do
      Thread.current.abort_on_exception = true

      require 'puppet_editor_services/protocol/debug_adapter'
      require 'puppet_editor_services/server/tcp'

      server_options = options.dup
      protocol_options = { :class => PuppetEditorServices::Protocol::DebugAdapter }.merge(options)
      handler_options = { :class => PuppetDebugServer::MessageHandler }.merge(options)
      # TODO: Add max threads?
      server_options[:servicename] = 'DEBUG SERVER'

      log_message(:debug, 'Using TCP Server')
      server = ::PuppetEditorServices::Server::Tcp.new(server_options, protocol_options, handler_options)
      trap('INT') do
        server.stop_services(true)
        PuppetDebugServer::PuppetDebugSession.instance.flow_control.assert_flag(:terminate)
      end
      server.start

      log_message(:info, 'Debug Server exited.')
      # Forcibly kill the Debug Session
      log_message(:info, 'Signalling Debug Session to terminate with extreme prejudice')
      PuppetDebugServer::PuppetDebugSession.instance.force_terminate
    end
  end

  def self.execute(rpc_thread)
    debug_session = PuppetDebugServer::PuppetDebugSession.instance
    debug_session.initialize_session

    # TODO: Can I use a real mutex here? might be hard with the rpc_thread.alive? call
    sleep(0.5) while !debug_session.flow_control.flag?(:start_puppet) && rpc_thread.alive? && !debug_session.flow_control.terminate?
    return unless rpc_thread.alive? || debug_session.flow_control.terminate?
    debug_session.run_puppet

    return unless rpc_thread.alive?
    debug_session.close
    rpc_thread.join
  end
end
