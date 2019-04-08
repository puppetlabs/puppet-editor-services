# Monkey Patch 3.x functions so where know where they were loaded from
require 'puppet/parser/functions'
module Puppet
  module Parser
    module Functions
      class << self
        alias_method :original_newfunction, :newfunction
        def newfunction(name, options = {}, &block)
          # See if we've hooked elsewhere. This can happen while in debuggers (pry). If we're not in the previous caller
          # stack then just use the last caller
          monkey_index = Kernel.caller_locations.find_index { |loc| loc.path.match(/puppet_monkey_patches\.rb/) }
          monkey_index = -1 if monkey_index.nil?
          caller = Kernel.caller_locations[monkey_index + 1]
          # Call the original new function method
          result = original_newfunction(name, options, &block)
          # Append the caller information
          result[:source_location] = {
            :source => caller.absolute_path,
            :line   => caller.lineno - 1 # Convert to a zero based line number system
          }
          monkey_append_function_info(name, result)

          result
        end

        def monkey_clear_function_info
          @monkey_function_list = {}
        end

        def monkey_append_function_info(name, value)
          @monkey_function_list = {} if @monkey_function_list.nil?
          @monkey_function_list[name] = {
            :arity           => value[:arity],
            :name            => value[:name],
            :type            => value[:type],
            :doc             => value[:doc],
            :source_location => value[:source_location]
          }
        end

        def monkey_function_list
          @monkey_function_list = {} if @monkey_function_list.nil?
          @monkey_function_list.clone
        end
      end
    end
  end
end

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

# The Ruby Legacy Function Instantiator doesn't have any error catching upon loading and would normally cause the entire puppet
# run to fail. However as we're a bit special, we can wrap the loader in rescue block and just continue on
require 'puppet/pops/loader/ruby_legacy_function_instantiator'
module Puppet
  module Pops
    module Loader
      class RubyLegacyFunctionInstantiator
        class << self
          alias_method :original_create, :create
        end

        def self.create(loader, typed_name, source_ref, ruby_code_string)
          original_create(loader, typed_name, source_ref, ruby_code_string)
        rescue LoadError, StandardError => err
          PuppetLanguageServerSidecar.log_message(:error, "[MonkeyPatch::Puppet::Pops::Loader::RubyLegacyFunctionInstantiator] Error loading legacy function #{typed_name.name}: #{err} #{err.backtrace}")
        end
      end
    end
  end
end

# The Ruby Function Instantiator doesn't have any error catching upon loading and would normally cause the entire puppet
# run to fail. However as we're a bit special, we can wrap the loader in rescue block and just continue on
require 'puppet/pops/loader/ruby_function_instantiator'
module Puppet
  module Pops
    module Loader
      class RubyFunctionInstantiator
        class << self
          alias_method :original_create, :create
        end

        def self.create(loader, typed_name, source_ref, ruby_code_string)
          original_create(loader, typed_name, source_ref, ruby_code_string)
        rescue LoadError, StandardError => err
          PuppetLanguageServerSidecar.log_message(:error, "[MonkeyPatch::Puppet::Pops::Loader::RubyLegacyFunctionInstantiator] Error loading function #{typed_name.name}: #{err} #{err.backtrace}")
        end
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

# DEBUG It's hard to remember what locations are searched. This simple monkey patch
# DEBUG will output what paths are being searched by what SmartPaths
# module Puppet::Pops
#   module Loader
#     module ModuleLoaders
#       class AbstractPathBasedModuleLoader
#         alias_method :original_discover, :discover

#         def discover(type, error_collector = nil, name_authority = Pcore::RUNTIME_NAME_AUTHORITY, &block)
#           PuppetLanguageServerSidecar.log_message(:debug, "--- AbstractPathBasedModuleLoader::discover name=#{self.loader_name}")
#           if name_authority == Pcore::RUNTIME_NAME_AUTHORITY
#             smart_paths.effective_paths(type).each do |sp|
#               PuppetLanguageServerSidecar.log_message(:debug, "Using SmartPath [#{sp.class.to_s}]Root=#{sp.root_path}")
#             end
#           end
#           original_discover(type, error_collector, name_authority, &block)
#         end
#       end
#     end
#   end
# end

# MUST BE LAST!!!!!!
# Suppress any warning messages to STDOUT.  It can pollute stdout when running in STDIO mode
Puppet::Util::Log.newdesttype :null_logger do
  def handle(msg)
    PuppetLanguageServerSidecar.log_message(:debug, "[PUPPET LOG] [#{msg.level}] #{msg.message}")
  end
end
