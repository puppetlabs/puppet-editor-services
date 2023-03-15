# frozen_string_literal: true

require 'puppetfile-resolver/puppetfile/parser/r10k_eval/module/invalid'
require 'puppetfile-resolver/puppetfile/parser/r10k_eval/module/forge'
require 'puppetfile-resolver/puppetfile/parser/r10k_eval/module/git'
require 'puppetfile-resolver/puppetfile/parser/r10k_eval/module/local'
require 'puppetfile-resolver/puppetfile/parser/r10k_eval/module/svn'

module PuppetfileResolver
  module Puppetfile
    module Parser
      module R10KEval
        module PuppetModule
          def self.from_puppetfile(title, args)
            return Module::Git.to_document_module(title, args) if Module::Git.implements?(title, args)
            return Module::Svn.to_document_module(title, args) if Module::Svn.implements?(title, args)
            return Module::Local.to_document_module(title, args) if Module::Local.implements?(title, args)
            return Module::Forge.to_document_module(title, args) if Module::Forge.implements?(title, args)

            Module::Invalid.to_document_module(title, args)
          end

          def self.parse_title(title)
            if (match = title.match(/\A(\w+)\Z/))
              [nil, match[1]]
            elsif (match = title.match(/\A(\w+)[-\/](\w+)\Z/))
              [match[1], match[2]]
            else
              raise ArgumentError, format("Module name (%<title>s) must match either 'modulename' or 'owner/modulename'", title: title)
            end
          end
        end
      end
    end
  end
end
