# frozen_string_literal: true

# Inject the workspace libdir on the fly
require 'puppet/util/autoload'
module Puppet
  module Util
    class Autoload
      class << self
        alias_method :original_module_directories, :module_directories
        def module_directories(env)
          result = original_module_directories(env)
          return result unless PuppetLanguageServerSidecar::Workspace.has_module_metadata?
          workspace_lib = File.join(PuppetLanguageServerSidecar::Workspace.root_path, 'lib')
          return result unless FileTest.directory?(workspace_lib)

          result << workspace_lib

          result
        end
      end
    end
  end
end

# Monkey patch the module loader and inject a workspace module
# into the modules memoization variable
require 'puppet/node/environment'
class Puppet::Node::Environment # rubocop:disable Style/ClassAndModuleChildren
  alias_method :original_modules, :modules
  alias_method :original_modules_by_path, :modules_by_path

  # The Puppet::Util::Json class doesn't exist in all puppet version.  Instead
  # just vendor the code here as it's a simple JSON loader only for metadata.json.
  # https://github.com/puppetlabs/puppet/blob/5.5.0/lib/puppet/util/json.rb#L32-L49
  def workspace_load_json(string, options = {})
    if defined? MultiJson
      begin
        MultiJson.load(string, options)
      rescue MultiJson::ParseError => e
        raise Puppet::Util::Json::ParseError.build(e, string)
      end
    else
      begin
        string = string.read if string.respond_to?(:read)

        options[:symbolize_names] = true if options.delete(:symbolize_keys)
        ::JSON.parse(string, options)
      rescue JSON::ParserError => e
        raise Puppet::Util::Json::ParseError.build(e, string)
      end
    end
  end

  def create_workspace_module_object(path)
    # Read the metadata to find the actual module name
    md_file = File.join(PuppetLanguageServerSidecar::Workspace.root_path, 'metadata.json')
    begin
      metadata = workspace_load_json(File.read(md_file, :encoding => 'utf-8'))
      return nil if metadata['name'].nil?
      # Extract the actual module name
      if Puppet::Module.is_module_directory_name?(metadata['name'])
        module_name = metadata['name']
      elsif Puppet::Module.is_module_namespaced_name?(metadata['name'])
        # Based on regex at https://github.com/puppetlabs/puppet/blob/f5ca8c05174c944f783cfd0b18582e2160b77d0e/lib/puppet/module.rb#L54
        result = /^[a-zA-Z0-9]+[-]([a-z][a-z0-9_]*)$/.match(metadata['name'])
        module_name = result[1]
      else
        # TODO: This is an invalid puppet module name in the metadata.json.  Should we log an error/warning?
        return nil
      end

      # The Puppet::Module initializer was changed in
      # https://github.com/puppetlabs/puppet/commit/935c0311dbaf1df03937822525c36b26de5390ef
      # We need to switch the creation based on whether the modules_strict_semver? method is available
      return Puppet::Module.new(module_name, path, self, modules_strict_semver?) if respond_to?('modules_strict_semver?')
      Puppet::Module.new(module_name, path, self)
    rescue StandardError
      nil
    end
  end

  def modules
    if @modules.nil?
      original_modules # rubocop:disable Style/IdenticalConditionalBranches
      if PuppetLanguageServerSidecar::Workspace.has_module_metadata?
        workspace_module = create_workspace_module_object(PuppetLanguageServerSidecar::Workspace.root_path)
        @modules << workspace_module unless workspace_module.nil?
      end

      @modules
    else
      original_modules # rubocop:disable Style/IdenticalConditionalBranches
    end
  end

  def modules_by_path
    result = original_modules_by_path

    result.keys.each do |key|
      if key == PuppetLanguageServerSidecar::Workspace.root_path && PuppetLanguageServerSidecar::Workspace.has_module_metadata?
        workspace_module = create_workspace_module_object(key)
        result[key] = workspace_module.nil? ? [] : [workspace_module]
      end
    end

    result
  end
end

# Inject the workspace as a module in all modulepaths
require 'puppet/settings/environment_conf'
class Puppet::Settings::EnvironmentConf # rubocop:disable Style/ClassAndModuleChildren
  alias_method :original_modulepath, :modulepath

  def modulepath
    result = original_modulepath

    if PuppetLanguageServerSidecar::Workspace.has_module_metadata? # rubocop:disable Style/IfUnlessModifier  Nicer to read like this
      result = result + File::PATH_SEPARATOR + PuppetLanguageServerSidecar::Workspace.root_path
    end

    result
  end
end

# Inject the workspace into the facter search paths
require 'puppet/indirector/facts/facter'
class Puppet::Node::Facts::Facter # rubocop:disable Style/ClassAndModuleChildren
  class << self
    alias_method :original_setup_search_paths, :setup_search_paths
    def setup_search_paths(request)
      result = original_setup_search_paths(request)
      return result unless PuppetLanguageServerSidecar::Workspace.has_module_metadata?

      additional_dirs = %w[lib plugins].map { |path| File.join(PuppetLanguageServerSidecar::Workspace.root_path, path, 'facter') }
                                       .select { |path| FileTest.directory?(path) }

      return result if additional_dirs.empty?
      Facter.search(*additional_dirs)
    end
  end
end
