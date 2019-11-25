# frozen_string_literal: true

# Add an additional method on Puppet Types to store their source location
require 'puppet/type'
module Puppet
  class Type
    class << self
      attr_accessor :_source_location
    end
  end
end

# Monkey Patch type loading so we can inject the source location information
require 'puppet/metatype/manager'
module Puppet
  module MetaType
    module Manager
      alias_method :original_newtype, :newtype
      def newtype(name, options = {}, &block)
        result = original_newtype(name, options, &block)

        if block_given? && !block.source_location.nil?
          result._source_location = {
            :source => block.source_location[0],
            :line   => block.source_location[1] - 1 # Convert to a zero based line number system
          }
        end
        result
      end
    end
  end
end

if Gem::Version.new(Puppet.version) >= Gem::Version.new('6.0.0')
  # Due to PUP-9509, need to monkey patch the cache loader
  # This need to be guarded on Puppet 6.0.0+
  require 'puppet/pops/loader/module_loaders'
  module Puppet
    module Pops
      module Loader
        module ModuleLoaders
          def self.cached_loader_from(parent_loader, loaders)
            LibRootedFileBased.new(parent_loader,
                                   loaders,
                                   NAMESPACE_WILDCARD,
                                   Puppet[:libdir],
                                   'cached_puppet_lib',
                                   %i[func_4x func_3x datatype])
          end
        end
      end
    end
  end
end

module Puppet
  module Pops
    module Loader
      class Loader
        def discover_paths(type, name_authority = Pcore::RUNTIME_NAME_AUTHORITY)
          if parent.nil?
            []
          else
            parent.discover_paths(type, name_authority)
          end
        end
      end
    end
  end
end

# The Null Loader was removed in Puppet 6.11.0+ (and friends) so monkey patch it back in!
# Last known source is at - https://github.com/puppetlabs/puppet/blob/6.10.1/lib/puppet/pops/loader/null_loader.rb
if defined?(::Puppet::Pops::Loader::NullLoader).nil?
  # This came direct from Puppet so ignore Rubocop
  # rubocop:disable Lint/UnusedMethodArgument
  # rubocop:disable Style/ClassAndModuleChildren
  # rubocop:disable Layout/SpaceAroundEqualsInParameterDefault
  # rubocop:disable Style/StringLiterals
  # rubocop:disable Style/TrivialAccessors
  # rubocop:disable Style/DefWithParentheses
  # The null loader is empty and delegates everything to its parent if it has one.
  #
  class ::Puppet::Pops::Loader::NullLoader < ::Puppet::Pops::Loader::Loader
    attr_reader :loader_name

    # Construct a NullLoader, optionally with a parent loader
    #
    def initialize(parent_loader=nil, loader_name = "null-loader")
      super(loader_name)
      @parent = parent_loader
    end

    # Has parent if one was set when constructed
    def parent
      @parent
    end

    def find(typed_name)
      if @parent.nil?
        nil
      else
        @parent.find(typed_name)
      end
    end

    def load_typed(typed_name)
      if @parent.nil?
        nil
      else
        @parent.load_typed(typed_name)
      end
    end

    def loaded_entry(typed_name, check_dependencies = false)
      if @parent.nil?
        nil
      else
        @parent.loaded_entry(typed_name, check_dependencies)
      end
    end

    # Has no entries on its own - always nil
    def get_entry(typed_name)
      nil
    end

    # Finds nothing, there are no entries
    def find(name)
      nil
    end

    # Cannot store anything
    def set_entry(typed_name, value, origin = nil)
      nil
    end

    def to_s()
      "(NullLoader '#{loader_name}')"
    end
  end
  # rubocop:enable Lint/UnusedMethodArgument
  # rubocop:enable Style/ClassAndModuleChildren
  # rubocop:enable Layout/SpaceAroundEqualsInParameterDefault
  # rubocop:enable Style/StringLiterals
  # rubocop:enable Style/TrivialAccessors
  # rubocop:enable Style/DefWithParentheses
end

# While this is not a monkey patch, but a new class, this class is used purely to
# enumerate the paths of puppet "things" that aren't already covered as part of the
# usual loaders. It is implemented as a null loader as it can't actually _load_
# anything.
module Puppet
  module Pops
    module Loader
      class PathDiscoveryNullLoader < Puppet::Pops::Loader::NullLoader
        def discover_paths(type, name_authority = Pcore::RUNTIME_NAME_AUTHORITY)
          result = []

          if type == :type
            autoloader = Puppet::Util::Autoload.new(self, 'puppet/type')
            current_env = current_environment

            # This is an expensive call
            if autoloader.method(:files_to_load).arity.zero?
              params = []
            else
              params = [current_env]
            end
            autoloader.files_to_load(*params).each do |file|
              name = file.gsub(autoloader.path + '/', '')
              expanded_name = autoloader.expand(name)
              absolute_name = Puppet::Util::Autoload.get_file(expanded_name, current_env)
              result << absolute_name unless absolute_name.nil?
            end
          end

          if type == :sidecar_manifest
            current_environment.modules.each do |mod|
              result.concat(mod.all_manifests)
            end
          end

          result.concat(super)
          result.uniq
        end

        private

        def current_environment
          begin
            env = Puppet.lookup(:environments).get!(Puppet.settings[:environment])
            return env unless env.nil?
          rescue Puppet::Environments::EnvironmentNotFound
            PuppetLanguageServerSidecar.log_message(:warning, "[Puppet::Pops::Loader::PathDiscoveryNullLoader::current_environment] Unable to load environment #{Puppet.settings[:environment]}")
          rescue StandardError => e
            PuppetLanguageServerSidecar.log_message(:warning, "[Puppet::Pops::Loader::PathDiscoveryNullLoader::current_environment] Error loading environment #{Puppet.settings[:environment]}: #{e}")
          end
          Puppet.lookup(:current_environment)
        end
      end
    end
  end
end

module Puppet
  module Pops
    module Loader
      class DependencyLoader
        def discover_paths(type, name_authority = Pcore::RUNTIME_NAME_AUTHORITY)
          result = []

          @dependency_loaders.each { |loader| result.concat(loader.discover_paths(type, name_authority)) }
          result.concat(super)
          result.uniq
        end
      end
    end
  end
end

module Puppet
  module Pops
    module Loader
      module ModuleLoaders
        class AbstractPathBasedModuleLoader
          def discover_paths(type, name_authority = Pcore::RUNTIME_NAME_AUTHORITY)
            result = []
            if name_authority == Pcore::RUNTIME_NAME_AUTHORITY
              smart_paths.effective_paths(type).each do |sp|
                relative_paths(sp).each do |rp|
                  result << File.join(sp.generic_path, rp)
                end
              end
            end
            result.concat(super)
            result.uniq
          end
        end
      end
    end
  end
end

# MUST BE LAST!!!!!!
# Suppress any warning messages to STDOUT.  It can pollute stdout when running in STDIO mode
Puppet::Util::Log.newdesttype :null_logger do
  def handle(msg)
    PuppetLanguageServerSidecar.log_message(:debug, "[PUPPET LOG] [#{msg.level}] #{msg.message}")
  end
end
