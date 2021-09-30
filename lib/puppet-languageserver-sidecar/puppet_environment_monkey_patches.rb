# frozen_string_literal: true

module Puppet::Environments # rubocop:disable Style/ClassAndModuleChildren
  class Directories
    # Monkey patch the environment loader.  When it attempts to load the special sidecar
    # environment, create a new Puppet::Node::Environment object for the workspace
    alias_method :original_get, :get
    def get(name)
      if name.intern == PuppetLanguageServerSidecar::PuppetHelper::SIDECAR_PUPPET_ENVIRONMENT.intern
        env_symbol = name.intern
        setting_values = Puppet.settings.values(env_symbol, Puppet.settings.preferred_run_mode)
        env = Puppet::Node::Environment.create(
          env_symbol,
          Puppet::Node::Environment.split_path(setting_values.interpolate(:modulepath)),
          setting_values.interpolate(:manifest),
          setting_values.interpolate(:config_version)
        )
        return env
      end

      original_get(name)
    end

    # Monkey patch the environment loader.  When it attempts to load the special sidecar
    # environment.conf file, create a new Puppet::Settings::EnvironmentConf object
    # from the workspace.
    alias_method :original_get_conf, :get_conf
    def get_conf(name)
      if name.intern == PuppetLanguageServerSidecar::PuppetHelper::SIDECAR_PUPPET_ENVIRONMENT.intern
        conf = Puppet::Settings::EnvironmentConf.load_from(PuppetLanguageServerSidecar::Workspace.root_path, @global_module_path)
        # Unfortunately the environment.conf expects OS style delimiters which means
        # it fails if written for windows and read on Unix and vice versa. So we just
        # inline munge the modulepath
        modpath = conf.get_raw_setting(:modulepath).value
        modpath.gsub!(':', File::PATH_SEPARATOR) if File::PATH_SEPARATOR != ':'
        modpath.gsub!(';', File::PATH_SEPARATOR) if File::PATH_SEPARATOR != ';'
        return conf
      end

      original_get_conf(name)
    end
  end
end

# Monkey patch the environment.  Normally it's not possible to modify environment settings.
# Add a method to get the underlying environment settings which can be used to modify
# settings on the fly.
class Puppet::Settings::EnvironmentConf # rubocop:disable Style/ClassAndModuleChildren
  def get_raw_setting(setting_name)
    section.setting(setting_name) if section
  end
end
