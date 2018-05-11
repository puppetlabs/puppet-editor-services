module PuppetLanguageServer
  module Puppetfile
    module R10K
      module Module
        class Local < PuppetLanguageServer::Puppetfile::R10K::Module::Base
          def self.implements?(_name, args)
            args.is_a?(Hash) && args.key?(:local)
          rescue StandardError
            false
          end

          def properties
            {
              :type => :local
            }
          end
        end
      end
    end
  end
end
