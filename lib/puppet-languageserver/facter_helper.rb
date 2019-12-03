# frozen_string_literal: true

module PuppetLanguageServer
  module FacterHelper
    @facts_loaded = nil

    def self.cache
      PuppetLanguageServer::PuppetHelper.cache
    end

    def self.sidecar_queue
      PuppetLanguageServer::PuppetHelper.sidecar_queue
    end

    # Facts
    def self.fact(name)
      return nil if @facts_loaded == false
      cache.object_by_name(:fact, name)
    end

    def self.fact_value(name)
      return nil if @facts_loaded == false
      object = cache.object_by_name(:fact, name)
      object.nil? ? nil : object.value
    end

    def self.fact_names
      return [] if @facts_loaded == false
      cache.object_names_by_section(:fact).map(&:to_s)
    end

    # This is a temporary module level variable.  It will be removed once FacterHelper
    # is refactored into a session_state style class
    def self.connection_id
      @connection_id
    end

    # This is a temporary module level variable.  It will be removed once FacterHelper
    # is refactored into a session_state style class
    def self.connection_id=(value)
      @connection_id = value
    end
  end
end
