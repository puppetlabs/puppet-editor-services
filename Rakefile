require 'rspec/core/rake_task'

rubocop_available = Gem::Specification::find_all_by_name('rubocop').any?
require 'rubocop/rake_task' if rubocop_available

desc 'Run rspec tests for the Language Server with coloring.'
RSpec::Core::RakeTask.new(:test_languageserver) do |t|
  t.rspec_opts = %w[--color --format documentation --default-path spec/languageserver]
  t.pattern    = 'spec/languageserver'
end

desc 'Run rspec tests for the Language Server with coloring.'
RSpec::Core::RakeTask.new(:test_languageserver_sidecar) do |t|
  t.rspec_opts = %w[--color --format documentation --default-path spec/languageserver-sidecar]
  t.pattern    = 'spec/languageserver-sidecar'
end

desc 'Run rspec tests for the Debug Server with coloring.'
RSpec::Core::RakeTask.new(:test_debugserver) do |t|
  t.rspec_opts = %w[--color --format documentation --default-path spec/debugserver]
  t.pattern    = 'spec/debugserver'
end

if rubocop_available
  desc 'Run RuboCop'
  RuboCop::RakeTask.new(:rubocop) do |task|
    task.options << '--display-cop-names'
    task.options << '--config'
    task.options << '.rubocop.yml'
  end
end

namespace :rubocop do
  desc "Generate the Rubocop Todo file"
  task :generate do
    begin
      sh "rubocop --auto-gen-config"
    rescue => exception
      # Ignore any errors
    end
  end
end

desc "Download and vendor required gems"
task :gem_revendor do
  require 'fileutils'

  gem_list = [
    {
      :directory => 'puppet-lint',
      :github_repo => 'https://github.com/rodjek/puppet-lint.git',
      :github_ref => '2.4.2',
    },
    {
      :directory => 'hiera-eyaml',
      :github_repo => 'https://github.com/voxpupuli/hiera-eyaml',
      :github_ref => 'v2.1.0',
    }
  ]

  # Clean out the vendor directory first
  puts "Clearing the vendor directory..."
  vendor_dir = File.join(File.dirname(__FILE__),'vendor')
  gem_list.each do |vendor|
    gem_dir = File.join(vendor_dir,vendor[:directory])
    FileUtils.rm_rf(gem_dir) if Dir.exists?(gem_dir)
  end
  Dir.mkdir(vendor_dir) unless Dir.exists?(vendor_dir)

  gem_list.each do |vendor|
    puts "Vendoring #{vendor[:directory]}..."
    gem_dir = File.join(vendor_dir,vendor[:directory])

    sh "git clone #{vendor[:github_repo]} #{gem_dir}"
    Dir.chdir(gem_dir) do
      sh 'git fetch origin'
      sh "git checkout #{vendor[:github_ref]}"
    end

    # Cleanup the gem directory...
    FileUtils.rm_rf(File.join(gem_dir,'.git'))
    FileUtils.rm_rf(File.join(gem_dir,'spec'))
    FileUtils.rm_rf(File.join(gem_dir,'features'))
  end

  # Generate the README
  readme = <<-HEREDOC
# Vendored Gems

The puppet language server is designed to run within the Puppet Agent ruby environment which means no access to Native Extensions or Gem bundling.

This means any Gems required outside of Puppet Agent for the language server must be vendored in this directory and the load path modified in the `puppet-languageserver` file.

Note - To comply with Licensing, the Gem source should be MIT licensed or even more unrestricted.

Note - To improve the packaging size, test files etc. were stripped from the Gems prior to committing.

Gem List
--------

HEREDOC
  gem_list.each { |vendor| readme += "* #{vendor[:directory]} (#{vendor[:github_repo]} ref #{vendor[:github_ref]})\n"}
  File.open(File.join(vendor_dir,'README.md'), 'wb') { |file| file.write(readme + "\n") }
end

desc "Create compressed files of the language and debug servers for release"
task :build do
  require 'fileutils'
  require 'archive/zip'
  require 'zlib'
  require 'minitar'
  require 'digest'

  project_dir = File.dirname(__FILE__)
  output_dir = File.join(project_dir, 'output')

  file_list = ['lib', 'vendor', 'puppet-languageserver', 'puppet-debugserver', 'puppet-languageserver-sidecar', 'LICENSE']
  # Remove files in the list that do not exist.
  file_list.reject! { |filepath| !File.exists?(filepath) }

  puts "Cleaning output directory..."
  FileUtils.rm_rf Dir.glob("#{output_dir}/*") if Dir.exists?(output_dir)
  Dir.mkdir(output_dir) unless Dir.exists?(output_dir)

  puts "Fetch editor services version..."
  require_relative 'lib/puppet-editor-services/version'
  version = PuppetEditorServices.version
  puts "Editor services is v#{version}"

  puts "Creating zip file..."
  zip_archive_file = File.join(output_dir,"puppet_editor_services_#{version}.zip")
  Archive::Zip.archive(zip_archive_file, file_list)
  puts "Created #{zip_archive_file}"

  puts "Creating tar file..."
  tar_archive_file = File.join(output_dir,"puppet_editor_services_#{version}.tar.gz")
  Minitar.pack(file_list, Zlib::GzipWriter.new(File.open(tar_archive_file, 'wb')))
  puts "Created #{tar_archive_file}"

  puts "Creating checksums..."
  [zip_archive_file, tar_archive_file].each do |filepath|
    sha = Digest::SHA256.hexdigest(File.open(filepath, 'rb') { |file| file.read })
    File.open(filepath + '.sha256', 'wb') { |file| file.write(sha) }
  end
  puts "Created checksums"
end

task :default => [:test]
