# These monkey patches are only required when the pup4api feature flag is specified

# The Ruby Legacy Function Instantiator doesn't have any error catching upon loading and would normally cause the entire puppet
# run to fail.  However as we're a bit special, we can wrap the loader in rescue block and just continue on
require 'puppet/pops/loader/ruby_legacy_function_instantiator'
module Puppet
  module Pops
    module Loader
      class RubyLegacyFunctionInstantiator
        class << self
          alias_method :original_create, :create
        end

        def self.create(loader, typed_name, source_ref, ruby_code_string)
          self.original_create(loader, typed_name, source_ref, ruby_code_string)
        rescue LoadError, StandardError => err
          PuppetLanguageServerSidecar.log_message(:error, "[MonkeyPatch::Puppet::Pops::Loader::RubyLegacyFunctionInstantiator] Error loading legacy function #{typed_name.name}: #{err} #{err.backtrace}")
        end
      end
    end
  end
end

# The Ruby Function Instantiator doesn't have any error catching upon loading and would normally cause the entire puppet
# run to fail.  However as we're a bit special, we can wrap the loader in rescue block and just continue on
require 'puppet/pops/loader/ruby_function_instantiator'
module Puppet
  module Pops
    module Loader
      class RubyFunctionInstantiator
        class << self
          alias_method :original_create, :create
        end

        def self.create(loader, typed_name, source_ref, ruby_code_string)
          self.original_create(loader, typed_name, source_ref, ruby_code_string)
        rescue LoadError, StandardError => err
          PuppetLanguageServerSidecar.log_message(:error, "[MonkeyPatch::Puppet::Pops::Loader::RubyLegacyFunctionInstantiator] Error loading function #{typed_name.name}: #{err} #{err.backtrace}")
        end
      end
    end
  end
end
