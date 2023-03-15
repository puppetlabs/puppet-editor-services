# frozen_string_literal: true

require 'puppetfile-resolver/spec_searchers/forge_configuration'
require 'puppetfile-resolver/spec_searchers/git_configuration'
require 'puppetfile-resolver/spec_searchers/local_configuration'

module PuppetfileResolver
  module SpecSearchers
    class Configuration
      attr_reader :local
      attr_reader :forge
      attr_reader :git

      def initialize
        @local = LocalConfiguration.new
        @forge = ForgeConfiguration.new
        @git = GitConfiguration.new
      end
    end
  end
end
