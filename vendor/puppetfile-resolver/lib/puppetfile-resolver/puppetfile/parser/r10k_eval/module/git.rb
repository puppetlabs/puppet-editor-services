# frozen_string_literal: true

require 'puppetfile-resolver/puppetfile/git_module'

module PuppetfileResolver
  module Puppetfile
    module Parser
      module R10KEval
        module Module
          module Git
            def self.implements?(_name, args)
              args.is_a?(Hash) && args.key?(:git)
            rescue StandardError
              false
            end

            def self.to_document_module(title, args)
              mod = ::PuppetfileResolver::Puppetfile::GitModule.new(title)
              mod.remote = args[:git]
              mod.ref = args[:ref] || args[:branch]
              mod.commit = args[:commit]
              mod.tag = args[:tag]
              mod
            end

            # TODO: https://github.com/puppetlabs/r10k/blob/master/doc/puppetfile.mkd#git
          end
        end
      end
    end
  end
end
