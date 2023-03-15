# frozen_string_literal: true

require 'puppetfile-resolver/puppetfile/base_module'

module PuppetfileResolver
  module Puppetfile
    class LocalModule < BaseModule
      def initialize(title)
        super
        @module_type = LOCAL_MODULE
      end
    end
  end
end
