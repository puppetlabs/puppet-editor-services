# frozen_string_literal: true

module PuppetfileResolver
  module Cache
    class Base
      def initialize(*_)
        @inmemory = {}
      end

      def exist?(name)
        @inmemory.key?(name)
      end

      def load(name)
        @inmemory[name]
      end

      def save(name, value, persist = false)
        @inmemory[name] = value
        persist(name, value) if persist
      end

      def persist(_name, content_string)
        raise 'Can only persist String data types' unless content_string.is_a?(String)
      end
    end
  end
end
