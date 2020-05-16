# frozen_string_literal: true

module PuppetLanguageServer
  module FacterHelper
    # Facts
    def self.fact(session_state, name)
      session_state.object_cache.object_by_name(:fact, name)
    end

    def self.fact_value(session_state, name)
      object = session_state.object_cache.object_by_name(:fact, name)
      object.nil? ? nil : object.value
    end

    def self.fact_names(session_state)
      session_state.object_cache.object_names_by_section(:fact).map(&:to_s)
    end

    def self.facts_to_hash
      fact_hash = {}
      session_state.object_cache.objects_by_section(:fact) { |factname, fact| fact_hash[factname.to_s] = fact.value }
      fact_hash
    end
  end
end
