module PuppetLanguageServer
  module Puppetfile
    module R10K
      module Module
        class Forge < PuppetLanguageServer::Puppetfile::R10K::Module::Base
          def self.implements?(name, args)
            !name.match(/\A(\w+)[-\/](\w+)\Z/).nil? && valid_version?(args)
          end

          def self.valid_version?(value)
            return false unless value.is_a?(String) || value.is_a?(Symbol)
            value == :latest || value.nil? || valid_version_string?(value)
          end

          def properties
            {
              :type => :forge
            }
          end

          # Version string matching regexes
          # From Semantic Puppet gem
          REGEX_NUMERIC = '(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)'.freeze # Major . Minor . Patch
          REGEX_PRE     = '(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?'.freeze # Prerelease
          REGEX_BUILD   = '(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?'.freeze # Build
          REGEX_FULL    = REGEX_NUMERIC + REGEX_PRE + REGEX_BUILD.freeze
          REGEX_FULL_RX = /\A#{REGEX_FULL}\Z/

          def self.valid_version_string?(value)
            match = value.match(REGEX_FULL_RX)
            if match.nil?
              false
            else
              prerelease = match[4]
              prerelease.nil? || prerelease.split('.').all? { |x| x !~ /^0\d+$/ }
            end
          end
        end
      end
    end
  end
end
