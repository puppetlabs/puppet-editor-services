# frozen_string_literal: true

require 'puppetfile-resolver/puppetfile/base_module'

module PuppetfileResolver
  module Puppetfile
    class ForgeModule < BaseModule
      def initialize(title)
        super
        @module_type = FORGE_MODULE
      end
    end
  end
end
