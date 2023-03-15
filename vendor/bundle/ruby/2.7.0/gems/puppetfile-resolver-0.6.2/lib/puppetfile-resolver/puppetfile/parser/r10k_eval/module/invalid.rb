# frozen_string_literal: true

# This is a special module definition.  It's the catchall when no other module type can handle it

require 'puppetfile-resolver/puppetfile/invalid_module'

module PuppetfileResolver
  module Puppetfile
    module Parser
      module R10KEval
        module Module
          module Invalid
            def self.implements?(_name, _args)
              true
            end

            def self.to_document_module(title, args)
              mod = ::PuppetfileResolver::Puppetfile::InvalidModule.new(title)
              mod.reason = format("Module %<title>s with args %<args>s doesn't have an implementation. (Are you using the right arguments?)", title: title, args: args.inspect)
              mod
            end
          end
        end
      end
    end
  end
end
