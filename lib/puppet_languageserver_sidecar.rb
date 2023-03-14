# frozen_string_literal: true

begin
  original_verbose = $VERBOSE
  $VERBOSE = nil

  require 'puppet_editor_services'
  require 'optparse'
  require 'logger'
  require 'json'

  %w[
    sidecar_protocol
  ].each do |lib|
    begin
      require "puppet-languageserver/#{lib}"
    rescue LoadError
      require File.expand_path(File.join(File.dirname(__FILE__), 'puppet-languageserver', lib))
    end
  end
ensure
  $VERBOSE = original_verbose
end

module PuppetLanguageServerSidecar
  def self.version
    PuppetEditorServices.version
  end

  def self.configure_featureflags(flags)
    @flags = flags
  end

  def self.featureflag?(flagname)
    return false if @flags.nil? || @flags.empty?
    @flags.include?(flagname)
  end

  def self.require_gems(options)
    original_verbose = $VERBOSE
    $VERBOSE = nil

    # Use specific Puppet Gem version if possible
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

    require 'puppet'

    # Validate the feature flags
    unless options[:flags].nil? || options[:flags].empty?
      flags = options[:flags]
      log_message(:debug, "Detected feature flags [#{options[:flags].join(', ')}]")

      configure_featureflags(flags)
    end

    require_list = %w[
      cache/base
      cache/null
      cache/filesystem
      puppet_parser_helper
      sidecar_protocol_extensions
      workspace
      facter_helper
      puppet_helper
      puppet_monkey_patches
      puppet_strings_helper
    ]

    require_list.each do |lib|
      begin
        require "puppet-languageserver-sidecar/#{lib}"
      rescue LoadError
        require File.expand_path(File.join(File.dirname(__FILE__), 'puppet-languageserver-sidecar', lib))
      end
    end
  ensure
    $VERBOSE = original_verbose
  end

  ACTION_LIST = %w[
    noop
    default_aggregate
    default_classes
    default_datatypes
    default_functions
    default_types
    node_graph
    resource_list
    workspace_aggregate
    workspace_classes
    workspace_datatypes
    workspace_functions
    workspace_types
    facts
  ].freeze

  class CommandLineParser
    def self.parse(options)
      # Set defaults here
      args = {
        action: nil,
        action_parameters: PuppetLanguageServer::Sidecar::Protocol::ActionParams.new,
        debug: nil,
        disable_cache: false,
        flags: [],
        output: nil,
        puppet_settings: [],
        puppet_version: nil,
        workspace: nil
      }

      opt_parser = OptionParser.new do |opts|
        opts.banner = 'Usage: puppet-languageserver-sidecar.rb [options]'

        opts.on('-a', '--action=NAME', ACTION_LIST, "The action for the sidecar to take. Expected #{ACTION_LIST}") do |name|
          args[:action] = name
        end

        opts.on('-c', '--action-parameters=JSON', 'JSON Encoded string containing the parameters for the sidecar action') do |json_string|
          ap = PuppetLanguageServer::Sidecar::Protocol::ActionParams.new
          begin
            ap.from_json!(json_string)
            args[:action_parameters] = ap
          rescue StandardError => e
            raise "Unable to parse the action parameters: #{e}"
          end
        end

        opts.on('-w', '--local-workspace=PATH', 'The workspace or file path that will be used to provide module-specific functionality. Default is no workspace path') do |path|
          args[:workspace] = path
        end

        opts.on('-o', '--output=PATH', 'The file to save the output from the sidecar. Default is output to STDOUT') do |path|
          args[:output] = path
        end

        opts.on('-p', '--puppet-settings=TEXT', Array, 'Comma delimited list of settings to pass into Puppet e.g. --vardir,/opt/test-fixture') do |text|
          args[:puppet_settings] = text
        end

        opts.on('--puppet-version=TEXT', String, 'The version of the Puppet Gem to use (defaults to latest version if not specified or the version does not exist) e.g. --puppet-version=5.4.0') do |text|
          args[:puppet_version] = text
        end

        opts.on('-f', '--feature-flags=FLAGS', Array, 'A list of comma delimited feature flags to pass the the sidecar') do |flags|
          args[:flags] = flags
        end

        opts.on('-n', '--[no-]cache', 'Enable or disable all caching inside the sidecar. By default caching is enabled.') do |cache|
          args[:disable_cache] = !cache
        end

        opts.on('--debug=DEBUG', "Output debug information.  Either specify a filename or 'STDOUT'. Default is no debug output") do |debug|
          args[:debug] = debug
        end

        opts.on('-h', '--help', 'Prints this help') do
          puts opts
          exit
        end

        opts.on('-v', '--version', 'Prints the Langauge Server version') do
          puts PuppetLanguageServerSidecar.version
          exit
        end
      end

      opt_parser.parse!(options.dup)

      raise('The action parameter is mandatory') if args[:action].nil?

      args
    end
  end

  def self.log_message(severity, message)
    PuppetEditorServices.log_message(severity, message)
  end

  def self.init_puppet_sidecar(options)
    PuppetEditorServices.init_logging(options)
    log_message(:info, "Language Server Sidecar is v#{PuppetLanguageServerSidecar.version}")
    log_message(:debug, 'Loading gems...')
    require_gems(options)
    log_message(:info, "Using Puppet v#{Puppet.version}")

    raise("Detected Puppet #{Puppet.version} however the Language Server Sidecar requires Puppet 5.0 and above") if Gem::Version.new(Puppet.version) < Gem::Version.new('5.0.0')

    log_message(:debug, "Detected additional puppet settings #{options[:puppet_settings]}")
    options[:puppet_settings].nil? ? Puppet.initialize_settings : Puppet.initialize_settings(options[:puppet_settings])

    PuppetLanguageServerSidecar::Workspace.detect_workspace(options[:workspace])
    log_message(:debug, 'Detected Module Metadata in the workspace') if PuppetLanguageServerSidecar::Workspace.has_module_metadata?
    log_message(:debug, 'Detected Environment Config in the workspace') if PuppetLanguageServerSidecar::Workspace.has_environmentconf?

    # Remove all other logging destinations except for ours
    Puppet::Util::Log.destinations.clear
    Puppet::Util::Log.newdestination('null_logger')

    true
  end

  def self.inject_workspace_as_module
    return false unless PuppetLanguageServerSidecar::Workspace.has_module_metadata?

    %w[puppet_modulepath_monkey_patches].each do |lib|
      begin
        require "puppet-languageserver-sidecar/#{lib}"
      rescue LoadError
        require File.expand_path(File.join(File.dirname(__FILE__), 'puppet-languageserver-sidecar', lib))
      end
    end

    log_message(:debug, 'Injected the workspace into the module loader')
    true
  end

  def self.inject_workspace_as_environment
    return false unless PuppetLanguageServerSidecar::Workspace.has_environmentconf?

    Puppet.settings[:environment] = PuppetLanguageServerSidecar::PuppetHelper::SIDECAR_PUPPET_ENVIRONMENT

    %w[puppet_environment_monkey_patches].each do |lib|
      begin
        require "puppet-languageserver-sidecar/#{lib}"
      rescue LoadError
        require File.expand_path(File.join(File.dirname(__FILE__), 'puppet-languageserver-sidecar', lib))
      end
    end

    log_message(:debug, 'Injected the workspace into the environment loader')
    true
  end

  def self.execute(options)
    unless Gem::Version.new(Puppet.version) >= Gem::Version.new('5.0.0')
      log_message(:error, 'Only Puppet Version 5.0 and above is supported.')
      return []
    end

    log_message(:debug, "Executing #{options[:action]} action")
    case options[:action].downcase
    when 'noop'
      []

    when 'default_aggregate'
      cache = options[:disable_cache] ? PuppetLanguageServerSidecar::Cache::Null.new : PuppetLanguageServerSidecar::Cache::FileSystem.new
      PuppetLanguageServerSidecar::PuppetHelper.retrieve_via_puppet_strings(cache, :object_types => PuppetLanguageServerSidecar::PuppetHelper.available_documentation_types)

    when 'default_classes'
      cache = options[:disable_cache] ? PuppetLanguageServerSidecar::Cache::Null.new : PuppetLanguageServerSidecar::Cache::FileSystem.new
      PuppetLanguageServerSidecar::PuppetHelper.retrieve_via_puppet_strings(cache, :object_types => [:class]).classes

    when 'default_datatypes'
      cache = options[:disable_cache] ? PuppetLanguageServerSidecar::Cache::Null.new : PuppetLanguageServerSidecar::Cache::FileSystem.new
      PuppetLanguageServerSidecar::PuppetHelper.retrieve_via_puppet_strings(cache, :object_types => [:datatype]).datatypes

    when 'default_functions'
      cache = options[:disable_cache] ? PuppetLanguageServerSidecar::Cache::Null.new : PuppetLanguageServerSidecar::Cache::FileSystem.new
      PuppetLanguageServerSidecar::PuppetHelper.retrieve_via_puppet_strings(cache, :object_types => [:function]).functions

    when 'default_types'
      cache = options[:disable_cache] ? PuppetLanguageServerSidecar::Cache::Null.new : PuppetLanguageServerSidecar::Cache::FileSystem.new
      PuppetLanguageServerSidecar::PuppetHelper.retrieve_via_puppet_strings(cache, :object_types => [:type]).types

    when 'node_graph'
      inject_workspace_as_module || inject_workspace_as_environment
      result = PuppetLanguageServerSidecar::Protocol::PuppetNodeGraph.new
      if options[:action_parameters]['source'].nil?
        log_message(:error, 'Missing source action parameter')
        return result.set_error('Missing source action parameter')
      end
      begin
        manifest = File.open(options[:action_parameters]['source'], 'r:UTF-8') { |f| f.read }
        PuppetLanguageServerSidecar::PuppetParserHelper.compile_node_graph(manifest)
      rescue StandardError => e
        log_message(:error, "Unable to compile the manifest. #{e}")
        result.set_error("Unable to compile the manifest. #{e}")
      end

    when 'resource_list'
      inject_workspace_as_module || inject_workspace_as_environment
      typename = options[:action_parameters]['typename']
      title = options[:action_parameters]['title']
      if typename.nil?
        log_message(:error, 'Missing typename action paramater')
        return []
      end
      PuppetLanguageServerSidecar::PuppetHelper.get_puppet_resource(typename, title)

    when 'workspace_aggregate'
      return nil unless inject_workspace_as_module || inject_workspace_as_environment
      cache = options[:disable_cache] ? PuppetLanguageServerSidecar::Cache::Null.new : PuppetLanguageServerSidecar::Cache::FileSystem.new
      PuppetLanguageServerSidecar::PuppetHelper.retrieve_via_puppet_strings(cache,
                                                                            :object_types => PuppetLanguageServerSidecar::PuppetHelper.available_documentation_types,
                                                                            :root_path    => PuppetLanguageServerSidecar::Workspace.root_path)

    when 'workspace_classes'
      return nil unless inject_workspace_as_module || inject_workspace_as_environment
      cache = options[:disable_cache] ? PuppetLanguageServerSidecar::Cache::Null.new : PuppetLanguageServerSidecar::Cache::FileSystem.new
      PuppetLanguageServerSidecar::PuppetHelper.retrieve_via_puppet_strings(cache,
                                                                            :object_types => [:class],
                                                                            :root_path    => PuppetLanguageServerSidecar::Workspace.root_path).classes

    when 'workspace_datatypes'
      return nil unless inject_workspace_as_module || inject_workspace_as_environment
      cache = options[:disable_cache] ? PuppetLanguageServerSidecar::Cache::Null.new : PuppetLanguageServerSidecar::Cache::FileSystem.new
      PuppetLanguageServerSidecar::PuppetHelper.retrieve_via_puppet_strings(cache,
                                                                            :object_types => [:datatype],
                                                                            :root_path    => PuppetLanguageServerSidecar::Workspace.root_path).datatypes

    when 'workspace_functions'
      return nil unless inject_workspace_as_module || inject_workspace_as_environment
      cache = options[:disable_cache] ? PuppetLanguageServerSidecar::Cache::Null.new : PuppetLanguageServerSidecar::Cache::FileSystem.new
      PuppetLanguageServerSidecar::PuppetHelper.retrieve_via_puppet_strings(cache,
                                                                            :object_types => [:function],
                                                                            :root_path    => PuppetLanguageServerSidecar::Workspace.root_path).functions

    when 'workspace_types'
      return nil unless inject_workspace_as_module || inject_workspace_as_environment
      cache = options[:disable_cache] ? PuppetLanguageServerSidecar::Cache::Null.new : PuppetLanguageServerSidecar::Cache::FileSystem.new
      PuppetLanguageServerSidecar::PuppetHelper.retrieve_via_puppet_strings(cache,
                                                                            :object_types => [:type],
                                                                            :root_path    => PuppetLanguageServerSidecar::Workspace.root_path).types

    when 'facts'
      # Can't cache for facts
      cache = PuppetLanguageServerSidecar::Cache::Null.new
      # Inject the workspace etc. if present
      injected = inject_workspace_as_module
      inject_workspace_as_environment unless injected
      PuppetLanguageServerSidecar::FacterHelper.retrieve_facts(cache)

    else
      log_message(:error, "Unknown action #{options[:action]}. Expected one of #{ACTION_LIST}")
    end
  end

  def self.output(result, options)
    if options[:output].nil? || options[:output].empty?
      $stdout.binmode
      $stdout.write(result.to_json)
    else
      File.open(options[:output], 'wb:UTF-8') do |f|
        f.write result.to_json
      end
    end
  end

  def self.execute_and_output(options)
    output(execute(options), options)
    nil
  end
end
