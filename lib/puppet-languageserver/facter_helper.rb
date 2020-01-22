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
    def self.facts_loaded?
      @facts_loaded.nil? ? false : @facts_loaded
    end

    def self.assert_facts_loaded
      @facts_loaded = true
    end

    def self.load_facts
      @facts_loaded = false
      sidecar_queue.execute_sync('facts', [])
    end

    def self.load_facts_async
      @facts_loaded = false
      sidecar_queue.enqueue('facts', [])
    end

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
  end
end
