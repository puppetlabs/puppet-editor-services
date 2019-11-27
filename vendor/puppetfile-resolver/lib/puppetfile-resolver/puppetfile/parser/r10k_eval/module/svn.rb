# frozen_string_literal: true

require 'puppetfile-resolver/puppetfile/svn_module'

module PuppetfileResolver
  module Puppetfile
    module Parser
      module R10KEval
        module Module
          module Svn
            def self.implements?(_name, args)
              args.is_a?(Hash) && args.key?(:svn)
            rescue StandardError
              false
            end

            def self.to_document_module(title, args)
              mod = ::PuppetfileResolver::Puppetfile::SvnModule.new(title)
              mod.remote = args[:svn]
              mod
            end

            # TODO: What about rev, revision, username, password?
            # https://github.com/puppetlabs/r10k/blob/master/doc/puppetfile.mkd#svn
          end
        end
      end
    end
  end
end
