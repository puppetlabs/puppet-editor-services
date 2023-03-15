# frozen_string_literal: true

require 'puppetfile-resolver/puppetfile/base_module'

module PuppetfileResolver
  module Puppetfile
    class SvnModule < BaseModule
      attr_accessor :remote

      def initialize(title)
        super
        @module_type = SVN_MODULE
      end
    end
  end
end
