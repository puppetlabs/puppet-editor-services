module PuppetLanguageServer
  module Puppetfile
    module R10K
      PUPPETFILE_MONIKER ||= 'Puppetfile'.freeze

      class Puppetfile
        def load!(puppetfile_contents)
          puppetfile = DSL.new(self)
          puppetfile.instance_eval(puppetfile_contents, PUPPETFILE_MONIKER)
        end

        class DSL
          def initialize(parent)
            @parent = parent
          end

          # @param [String] name
          # @param [*Object] args
          def mod(_name, _args = nil)
          end

          # @param [String] forge
          def forge(_location)
          end

          # @param [String] moduledir
          def moduledir(_location)
          end

          def method_missing(method, *_args) # rubocop:disable Style/MethodMissing
            raise NoMethodError, format("Unknown method '%<method>s'", method: method)
          end
        end
      end
    end
  end
end
