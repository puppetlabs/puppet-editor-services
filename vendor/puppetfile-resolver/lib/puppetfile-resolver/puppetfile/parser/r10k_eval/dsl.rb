# frozen_string_literal: true

require 'puppetfile-resolver/puppetfile/parser/r10k_eval/puppet_module'

module PuppetfileResolver
  module Puppetfile
    module Parser
      module R10KEval
        class DSL
          def initialize(puppetfile_document)
            @document = puppetfile_document
          end

          # @param [String] name
          # @param [*Object] args
          def mod(name, args = nil)
            # Get the module object
            mod = PuppetModule.from_puppetfile(name, args)
            # Inject the file location
            line_num = find_load_line_number
            mod.location.start_line = line_num
            mod.location.end_line = line_num
            # Append to the list of modules
            @document.add_module(mod)
          end

          # @param [String] forge
          def forge(location)
            @document.forge_uri = location
          end

          # @param [String] moduledir
          def moduledir(_location)
          end

          def method_missing(method_name, *_args) # rubocop:disable Style/MethodMissingSuper, Style/MissingRespondToMissing
            raise NoMethodError, "Unknown method #{method_name}"
          end

          private

          def find_load_line_number
            loc = Kernel.caller_locations
                        .find { |call_loc| call_loc.absolute_path == ::PuppetfileResolver::Puppetfile::Parser::R10KEval::PUPPETFILE_MONIKER }
            loc.nil? ? 0 : loc.lineno - 1 # Line numbers from ruby are base 1
          end
        end
      end
    end
  end
end
