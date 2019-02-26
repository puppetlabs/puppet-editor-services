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

          # Calculate function signature based on arity
          # Ref: https://www.rubydoc.info/gems/puppet/Puppet/Parser/Functions#newfunction-class_method
          # The [arity](en.wikipedia.org/wiki/Arity) of the function. When specified as a positive integer the function is expected to receive exactly the specified number
          # of arguments. When specified as a negative number, the function is expected to receive _at least_ the absolute value of the specified number of arguments
          # incremented by one. For example, a function with an arity of `-4` is expected to receive at minimum 3 arguments. A function with the default arity of `-1`
          # accepts zero or more arguments. A function with an arity of 2 must be provided with exactly two arguments, no more and no less. Added in Puppet 3.1.0.
          arg_count = value[:arity] < 0 ? (value[:arity] + 1) * -1 : value[:arity]
          signature = name.to_s + '(' + (1..arg_count).map { |i| "param#{i}" }.join(', ') + ')'

          @monkey_function_list[name] = {
            :name            => value[:name],
            :type            => value[:type],
            :doc             => value[:doc],
            :source_location => value[:source_location],
            :signatures      => [signature],
            :version         => 3
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
# require 'puppet/functions'
# module Puppet
#   class Function
#     class << self
#       attr_accessor :_yyysource_location
#     end
#   end
# end

module PuppetLanguageServerSidecar
  module PuppetHelper

    V3_FUNCTION = :v3_function
    V4_FUNCTION = :v4_function

    def self.function_to_signature_hash(func_version, func)
      result = []
      # Generate the signature information
      # TODO What about params with no name? e.g. no param specified
      # TODO What about blocks?

      func.signatures.each do |signature|
        require 'pry'; binding.pry
        return_type = signature.type.return_type.nil? ? '' : "[#{signature.type.return_type}] "
        params = []
        signature.type.param_types.each_with_index do |param_type, idx|
          # The default formatter expands aliases and makes type names HUGE. Just use the shorter `string` method
          param_type_string = Puppet::Pops::Types::TypeFormatter.singleton.string(param_type)
          # It is possible to have no param name, just substitute one in.
          param_name_string = signature.param_names[idx].nil? ? " param#{idx + 1}" : " #{signature.param_names[idx]}"

          #require 'pry'; binding.pry if name == 'default_pup4_function'

          params << "[#{param_type_string}]#{param_name_string}"
        end

        result << "#{return_type}#{func.name}(#{params.join(', ')})"
      end

      result
    end
  end
end

module Puppet
  module Functions
    class << self
      alias_method :original_create_function, :create_function
    end

    def self.create_function(func_name, function_base = Function, &block)
      # See if we've hooked elsewhere. Also be specific about which function in the puppet_monkey_patches.rb we are looking for
      # This can happen while in debuggers (pry). If we're not in the previous caller stack then just use the last caller
      monkey_index = Kernel.caller_locations.find_index { |loc| loc.path.match(/puppet_monkey_patches\.rb/) && loc.label == 'create_function' }
      monkey_index = -1 if monkey_index.nil?
      caller = Kernel.caller_locations[monkey_index + 1]
      # Call the original new function method
      result = original_create_function(func_name, function_base, &block)

      monkey_append_function_info(result.name, result,
                                  :source_location => {
                                    :source => caller.absolute_path,
                                    :line   => caller.lineno - 1 # Convert to a zero based line number system
                                  })

      result
    end

    def self.monkey_clear_function_info
      @monkey_function_list = {}
    end

    def self.monkey_append_function_info(name, value, options = {})
      @monkey_function_list = {} if @monkey_function_list.nil?


      signatures = value.signatures.map do |signature|
        return_type = signature.type.return_type.nil? ? '' : "[#{signature.type.return_type}] "
        params = []
        signature.type.param_types.each_with_index do |param_type, idx|
          # The default formatter expands aliases and makes type names HUGE.  Just use the shorter `string` method
          param_type_string = Puppet::Pops::Types::TypeFormatter.singleton.string(param_type)
          # It is possible to have no param name, just substitute one in.
          param_name_string = signature.param_names[idx].nil? ? " param#{idx + 1}" : " #{signature.param_names[idx]}"

          #require 'pry'; binding.pry if name == 'default_pup4_function'

          params << "[#{param_type_string}]#{param_name_string}"
        end

        "#{return_type}#{name}(#{params.join(', ')})"
      end

      @monkey_function_list[name] = {
        :name       => value.name,
        :signatures => signatures, # PuppetLanguageServerSidecar::PuppetHelper.function_to_signature_hash(PuppetLanguageServerSidecar::PuppetHelper::V4_FUNCTION, value),
        :type       => :rvalue, # All Puppet 4 functions will return a value
        :doc        => nil, # Docs are filled in post processing via Yard
        :version    => 4
      }.merge(options)
    end

    def self.monkey_function_list
      @monkey_function_list = {} if @monkey_function_list.nil?
      @monkey_function_list.clone
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

# DEBUG PATCHING
# module Puppet::Pops
#   module Loader
#     module ModuleLoaders
#       class AbstractPathBasedModuleLoader
#         alias_method :original_discover, :discover
#         alias_method :original_find, :find

#         def discover(type, error_collector = nil, name_authority = Pcore::RUNTIME_NAME_AUTHORITY, &block)
#           puts "**************** discover Loader=#{self.loader_name} Type=#{type}"
#           #return [] if self.loader_name == 'puppet_system'
#           original_discover(type, error_collector, name_authority, &block)
#         end

#         def find(typed_name)
#           puts "* find Loader=#{self.loader_name} typed_name.name=#{typed_name.name}"
#           #require 'pry'; binding.pry if self.loader_name == 'puppetlabs-reboot' && typed_name.name == 'reboot::sleep'
#           original_find(typed_name)
#         end
#       end
#     end
#   end
# end

# module Puppet::Pops
#   module Loader
#     class BaseLoader
#       alias_method :original_load_typed, :load_typed
#       alias_method :original_internal_load, :internal_load
#       def load_typed(typed_name)
#         puts "load_typed Loader=#{self.loader_name} Type=#{typed_name.name}"
#         original_load_typed(typed_name)
#       end

#       def internal_load(typed_name)
#         puts "internal_load Loader=#{self.loader_name} Type=#{typed_name.name}"
#         original_internal_load(typed_name)
#       end
#     end
#   end
# end
# DEBUG PATCHING

# Due to PUP-9509 need to monkey patch the cache loader
# TODO: Does this need to be guarded on Puppet version? e.g. this doesn't exist before 5.4.0
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
            [:func_4x, :func_3x, :datatype]
          )
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
