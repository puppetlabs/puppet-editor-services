# frozen_string_literal: true

require 'puppet_editor_services/server/base'

module PuppetEditorServices
  module Server
    def self.current_server
      @@current_server # rubocop:disable Style/ClassVars  This is fine
    end

    def self.current_server=(value)
      @@current_server = value # rubocop:disable Style/ClassVars  This is fine
    end
  end
end
