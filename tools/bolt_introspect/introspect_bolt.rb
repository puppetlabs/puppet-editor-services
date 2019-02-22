require 'open3'
require 'json'

class Introspecter
  attr_reader :root_dir
  attr_reader :bolt_gem_dir
  attr_reader :static_data_dir

  def initialize
    bolt_gem = Gem::Specification.find_by_name('bolt')
    raise "Could not find the bolt gem" if bolt_gem.nil?
    @bolt_gem_dir = bolt_gem.gem_dir
    raise "Could not find the bolt gem directory" if @bolt_gem_dir.nil?
    @root_dir = File.expand_path(File.join(__dir__, '..', '..'))
    @static_data_dir = File.join(root_dir, 'lib', 'puppet-languageserver', 'static_data')

    # Needed for the sidecar protocol classes
    require_relative File.join(@root_dir, 'lib', 'puppet-languageserver', 'sidecar_protocol.rb')
  end

  def clean_output_dir
    Dir.glob(File.join(static_data_dir, 'bolt-*.json')) do |file|
      puts "Removing #{file} ..."
      File.delete(file)
    end
  end

  def mock_metadata(module_name)
    <<-METADATA
    { "name": "pes-#{module_name}", "version": "1.0.0", "author": "pes", "license": "MIT", "summary": "Summary", "source": "bolt-gem", "dependencies": [] }
    METADATA
  end

  def sanitise_aggregate(file_path)
    # Read in the current content
    content = File.open(file_path, 'rb:utf-8') { |f| f.read }
    agg = PuppetLanguageServer::Sidecar::Protocol::AggregateMetadata.new.from_json!(content)

    agg.each_list do |_, items|
      items.each do |item|
        # Scrub all of the source locations as it is not relevant
        item.calling_source = nil if item.respond_to?(:calling_source)
        item.source         = nil if item.respond_to?(:source)
        item.line           = nil if item.respond_to?(:line)
        item.char           = nil if item.respond_to?(:char)
        item.length         = nil if item.respond_to?(:length)
      end
    end

    # Write the santised content
    File.open(file_path, 'wb:UTF-8') { |f| f.write agg.to_json }
  end

  def introspect_module(absolute_module_path)
    module_name = File.basename(absolute_module_path)
    puts "Introspecting #{absolute_module_path} ..."

    # Create the arguments to pass to the sidecar
    output_file = File.join(static_data_dir, "bolt-#{module_name}.json")
    args = [
      'bundle',
      'exec',
      'ruby',
      File.join(root_dir, 'puppet-languageserver-sidecar'),
      '--action=workspace_aggregate',
      "--local-workspace=#{absolute_module_path}",
      '--feature-flags=puppetstrings',
      '--no-cache',
      '--debug=STDOUT',
      "--output=#{output_file}"
    ]

    metadata_file = File.join(absolute_module_path, 'metadata.json')
    metadata_exists = File.exist?(metadata_file)
    unless metadata_exists
      File.open(metadata_file, 'wb:UTF-8') { |f| f.write(mock_metadata(module_name)) }
    end

    begin
      stdout_str, std_err_str, status = Open3.capture3(*args)
    ensure
      # Cleanup after ourselves
      File.delete(metadata_file) unless metadata_exists
    end

    unless status.success?
      puts "Failed to introspect #{absolute_module_path}: #{std_err_str}"
      raise "Failed to introspect #{absolute_module_path}"
    end

    puts "--- Sidecar output"
    puts stdout_str
    puts "---"
    puts "Sanitising #{output_file} ..."
    sanitise_aggregate(output_file)
  end

  def introspect_modules_path(absolute_modules_path)
    Dir.glob(File.join(absolute_modules_path, '*')) do |absolute_module_path|
      next unless File.directory?(absolute_module_path)

      sub_dirs = Dir.glob(File.join(absolute_module_path, '*')).select { |p| File.directory?(p) }.map { |p| File.basename(p) }
      unless sub_dirs.include?('lib') || sub_dirs.include?('plans')
        puts "Ignoring #{absolute_module_path} as it does not have any subdirectories to indicate it is indeed a Puppet module"
        next
      end

      introspect_module(absolute_module_path)
    end
  end
end

introspecter = Introspecter.new

introspecter.clean_output_dir

['bolt-modules', 'modules'].each do |modules_path|
  absolute_modules_path = File.join(introspecter.bolt_gem_dir, modules_path)
  unless Dir.exist?(absolute_modules_path)
    warn "Bolt module path #{absolute_modules_path} does not exist"
    next
  end

  introspecter.introspect_modules_path(absolute_modules_path)
end
