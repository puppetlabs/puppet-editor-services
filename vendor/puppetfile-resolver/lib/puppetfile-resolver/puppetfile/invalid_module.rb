# frozen_string_literal: true

require 'puppetfile-resolver/puppetfile/base_module'

module PuppetfileResolver
  module Puppetfile
    class InvalidModule < BaseModule
      attr_accessor :reason

      def initialize(title)
        super
        @module_type = INVALID_MODULE
      end
    end
  end
end
