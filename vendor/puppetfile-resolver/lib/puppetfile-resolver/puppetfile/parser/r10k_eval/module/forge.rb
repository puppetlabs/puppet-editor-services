# frozen_string_literal: true

require 'puppetfile-resolver/puppetfile/forge_module'

module PuppetfileResolver
  module Puppetfile
    module Parser
      module R10KEval
        module Module
          class Forge
            def self.implements?(name, args)
              !name.match(/\A(\w+)[-\/](\w+)\Z/).nil? && valid_version?(args)
            end

            def self.to_document_module(title, args)
              mod = ::PuppetfileResolver::Puppetfile::ForgeModule.new(title)
              mod.version = args if valid_version?(args)
              mod
            end

            def self.valid_version?(value)
              return false unless value.is_a?(String) || value.is_a?(Symbol)
              value == :latest || value.nil? || valid_version_string?(value)
            end
            private_class_method :valid_version?

            # Version string matching regexes
            # From Semantic Puppet gem
            REGEX_NUMERIC = '(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)' # Major . Minor . Patch
            REGEX_PRE     = '(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?' # Prerelease
            REGEX_BUILD   = '(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?' # Build
            REGEX_FULL    = REGEX_NUMERIC + REGEX_PRE + REGEX_BUILD.freeze
            REGEX_FULL_RX = /\A#{REGEX_FULL}\Z/.freeze

            def self.valid_version_string?(value)
              match = value.match(REGEX_FULL_RX)
              if match.nil?
                false
              else
                prerelease = match[4]
                prerelease.nil? || prerelease.split('.').all? { |x| x !~ /^0\d+$/ }
              end
            end
            private_class_method :valid_version_string?
          end
        end
      end
    end
  end
end
