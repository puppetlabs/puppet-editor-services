module PuppetLanguageServer
  module Puppetfile
    module R10K
      module Module
        class Git < PuppetLanguageServer::Puppetfile::R10K::Module::Base
          def self.implements?(_name, args)
            args.is_a?(Hash) && args.key?(:git)
          rescue StandardError
            false
          end

          def properties
            {
              :type => :git
            }
          end
        end
      end
    end
  end
end
