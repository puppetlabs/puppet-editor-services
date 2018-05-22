module PuppetLanguageServer
  module Puppetfile
    module R10K
      module Module
        class Svn < PuppetLanguageServer::Puppetfile::R10K::Module::Base
          def self.implements?(_name, args)
            args.is_a?(Hash) && args.key?(:svn)
          rescue StandardError
            false
          end

          def properties
            {
              :type => :svn
            }
          end
        end
      end
    end
  end
end
