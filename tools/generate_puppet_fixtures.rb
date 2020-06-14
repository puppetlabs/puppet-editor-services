require 'open3'
require 'json'

# Creates a JSON file of a default Puppet gem installation.  Used in the fixtures directory to
# simulate the result of a sidecar default_aggregate job.

class Introspecter
  attr_reader :root_dir
  attr_reader :fixture_file
  attr_reader :fixture_fact_file

  def initialize
    @root_dir = File.expand_path(File.join(__dir__, '..'))
    @fixture_file = File.join(root_dir, 'spec', 'languageserver', 'fixtures', 'puppet_object_cache.json')
    @fixture_fact_file = File.join(root_dir, 'spec', 'languageserver', 'fixtures', 'fact_object_cache.json')

    # Needed for the sidecar protocol classes
    require_relative File.join(@root_dir, 'lib', 'puppet-languageserver', 'sidecar_protocol.rb')
  end

  def clean_output_file
    if File.exist?(fixture_file)
      puts "Removing #{fixture_file} ..."
      File.delete(fixture_file)
    end
    if File.exist?(fixture_fact_file)
      puts "Removing #{fixture_fact_file} ..."
      File.delete(fixture_fact_file)
    end
  end

  def sanitise_aggregate(file_path)
    # Read in the current content
    content = File.open(file_path, 'rb:utf-8') { |f| f.read }
    agg = PuppetLanguageServer::Sidecar::Protocol::AggregateMetadata.new.from_json!(content)

    agg.each_list do |_, items|
      items.each do |item|
        # Scrub all of the source locations as it is not relevant
        item.calling_source = scrub_path(item.calling_source) if item.respond_to?(:calling_source)
        item.source         = scrub_path(item.source) if item.respond_to?(:source)
        item.line           = nil if item.respond_to?(:line) && item.source.nil?
        item.char           = nil if item.respond_to?(:char) && item.source.nil?
        item.length         = nil if item.respond_to?(:length) && item.source.nil?
      end
    end

    # Write the santised content
    File.open(file_path, 'wb:UTF-8') { |f| f.write JSON.pretty_generate(agg) }
  end

  def scrub_path(path)
    return nil if path.nil?
    return nil unless path.start_with?(puppet_gem_path)
    path.slice(puppet_gem_path.length..-1)
  end

  def puppet_gem_path
    return @puppet_gem_path unless @puppet_gem_path.nil?
    puppet_gems = Gem::Specification.select { |item| item.name.casecmp('puppet').zero? }
    raise "Multiple or no Puppet gems found" if puppet_gems.count != 1
    puppet_gem = puppet_gems.first
    @puppet_gem_path = puppet_gem.full_gem_path
  end

  def introspect
    introspect_puppet
    introspect_facter
  end

  def introspect_puppet
    puts "Introspecting Puppet ..."

    # Create the arguments to pass to the sidecar
    args = [
      'bundle',
      'exec',
      'ruby',
      File.join(root_dir, 'puppet-languageserver-sidecar'),
      '--action=default_aggregate',
      # Don't use the cache. Force fresh data
      '--no-cache',
      '--debug=STDOUT',
      # Stop processing any environment based things on my local computer
      # Use directories which do not exist
      '--puppet-settings=--vardir,does_not_exist_cache,--confdir,does_not_exist_confdir',
      "--output=#{fixture_file}"
    ]

    stdout_str, std_err_str, status = Open3.capture3(*args)

    unless status.success?
      puts "Failed to introspect Puppet: #{std_err_str}"
      raise "Failed to introspect Puppet"
    end

    puts "--- Sidecar output"
    puts stdout_str
    puts "---"
    puts "Sanitising #{fixture_file} ..."
    sanitise_aggregate(fixture_file)
  end

  def introspect_facter
    puts "Introspecting Facter via FacterDB ..."

    require 'net/http'
    result = ::JSON.parse(Net::HTTP.get(URI('https://raw.githubusercontent.com/camptocamp/facterdb/master/facts/3.14/windows-2012%20r2-x86_64.facts')))

    facts = PuppetLanguageServer::Sidecar::Protocol::FactList.new
    result.each do |key, value|
      facts << PuppetLanguageServer::Sidecar::Protocol::Fact.new.from_h!('key' => key, 'value' => value)
    end

    File.open(fixture_fact_file, 'wb:UTF-8') { |f| f.write JSON.pretty_generate(facts) }
  end
end

introspecter = Introspecter.new

introspecter.clean_output_file

introspecter.introspect
