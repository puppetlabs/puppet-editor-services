# frozen_string_literal: true

# This is not supposed to be a fully fledged CLI for the resolver, as this gem is designed to be used
# as a library. The CLI is offered as an example as to how to use the library.

# Add the resolver into the load path
lib_root = File.expand_path(File.join(__dir__, 'lib'))
$LOAD_PATH.unshift(lib_root)

require 'puppetfile-resolver'
require 'optparse'

class CommandLineParser
  def self.parse(options)
    # Set defaults here
    args = {
      debug: false,
      cache_dir: nil,
      module_paths: [],
      path: nil,
      puppet_version: nil,
      strict: false
    }

    opt_parser = OptionParser.new do |opts|
      opts.banner = 'Usage: puppetfile-cli.rb [options]'

      opts.on('-pPATH', '--path=PATH', 'Puppetfile to parse') do |path|
        args[:path] = path
      end

      opts.on('-vVERSION', '--puppet_version=VERSION', 'Restrict the resolver to only modules which support the specified Puppet version') do |version|
        args[:puppet_version] = version
      end

      opts.on('-cDIR', '--cache_directory=DIR', 'Directory to the persistent on disk cache.  Optional') do |cache_dir|
        args[:cache_dir] = cache_dir
      end

      opts.on('--debug', 'Output debug information. Default is no debug output') do
        args[:debug] = true
      end

      opts.on('-s', '--strict', 'Do not allow missing dependencies. Default false which marks dependencies as missing and does not raise an error.') do
        args[:strict] = true
      end

      opts.on('-mTEXT', '--module_paths=TEXT', Array, 'Comma delimited list of modules paths to search') do |text|
        args[:module_paths] = text
      end
    end

    opt_parser.parse!(options.dup)
    args
  end
end

options = CommandLineParser.parse(ARGV)
raise 'Missing --path' if options[:path].nil?

# Configure the cache
if options[:cache_dir].nil?
  cache = nil
else
  require 'puppetfile-resolver/cache/persistent'
  cache = PuppetfileResolver::Cache::Persistent.new(options[:cache_dir])
end

# Parse the Puppetfile into an object model
content = File.open(options[:path], 'rb') { |f| f.read }
require 'puppetfile-resolver/puppetfile/parser/r10k_eval'
puppetfile = ::PuppetfileResolver::Puppetfile::Parser::R10KEval.parse(content)

# Make sure the Puppetfile is valid
unless puppetfile.valid?
  puts 'Puppetfile is not valid'
  puppetfile.validation_errors.each { |err| puts err }
  exit 1
end

# Create the resolver
resolver = PuppetfileResolver::Resolver.new(puppetfile, options[:puppet_version])

# Configure the resolver
if options[:debug]
  require 'puppetfile-resolver/ui/debug_ui'
  ui = PuppetfileResolver::UI::DebugUI.new
else
  ui = nil
end
opts = { cache: cache, ui: ui, module_paths: options[:module_paths], allow_missing_modules: !options[:strict] }

# Resolve
result = resolver.resolve(opts)

# Output errors
result.validation_errors.each { |err| puts "Resolution Validation Error: #{err}\n" }

# Output the Graph in a DOT format
puts "\n--- Dependency Graph"
puts result.to_dot
