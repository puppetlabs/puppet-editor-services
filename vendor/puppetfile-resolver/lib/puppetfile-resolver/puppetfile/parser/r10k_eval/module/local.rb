# frozen_string_literal: true

require 'puppetfile-resolver/puppetfile/local_module'

module PuppetfileResolver
  module Puppetfile
    module Parser
      module R10KEval
        module Module
          class Local
            def self.implements?(_name, args)
              args.is_a?(Hash) && args.key?(:local)
            rescue StandardError
              false
            end

            def self.to_document_module(title, _args)
              mod = ::PuppetfileResolver::Puppetfile::LocalModule.new(title)
              mod
            end
          end
        end
      end
    end
  end
end
