begin
  original_verbose = $VERBOSE
  $VERBOSE = nil

  require 'puppet-editor-services'

  %w[
  ].each do |lib|
    begin
      require "puppet-languageserver-sidecar/#{lib}"
    rescue LoadError
      require File.expand_path(File.join(File.dirname(__FILE__), 'puppet-languageserver-sidecar', lib))
    end
  end

  require 'puppet'
  require 'optparse'
  require 'logger'
ensure
  $VERBOSE = original_verbose
end

module PuppetLanguageServerSidecar
  def self.version
    PuppetEditorServices.version
  end

  class CommandLineParser
    def self.parse(options)
      # Set defaults here
      args = {
        debug: nil,
        workspace: nil
      }

      opt_parser = OptionParser.new do |opts|
        opts.banner = 'Usage: puppet-languageserver-sidecar.rb [options]'

        opts.on('--debug=DEBUG', "Output debug information.  Either specify a filename or 'STDOUT'.  Default is no debug output") do |debug|
          args[:debug] = debug
        end

        opts.on('--local-workspace=PATH', 'The workspace or file path that will be used to provide module-specific functionality. Default is no workspace path.') do |path|
          args[:workspace] = path
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
      args
    end
  end

  def self.log_message(severity, message)
    PuppetEditorServices.log_message(severity, message)
  end

  def self.init_puppet_sidecar(options)
    PuppetEditorServices.init_logging(options)
    log_message(:info, "Language Server Sidecar is v#{PuppetLanguageServerSidecar.version}")
    log_message(:info, "Using Puppet v#{Puppet.version}")

    options[:puppet_settings].nil? ? Puppet.initialize_settings : Puppet.initialize_settings(options[:puppet_settings])

    # Remove all other logging destinations except for ours
    Puppet::Util::Log.destinations.clear
    Puppet::Util::Log.newdestination('null_logger')

    true
  end

  def self.execute(options)
  end
end
