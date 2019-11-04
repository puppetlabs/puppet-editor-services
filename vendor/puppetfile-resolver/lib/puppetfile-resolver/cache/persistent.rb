# frozen_string_literal: true

require 'puppetfile-resolver/cache/base'

# TODO: This is currently redundant as there are no calls to persist the data

module PuppetfileResolver
  module Cache
    class Persistent < Base
      def initialize(cache_directory)
        super

        require 'digest'
        require 'json'
        @cache_directory = cache_directory
        Dir.mkdir(@cache_directory) unless Dir.exist?(@cache_directory)
      end

      def exist?(name)
        result = super
        return result if result
        filename = File.join(@cache_directory, to_cache_name(name))
        File.exist?(filename)
      end

      def load(name)
        result = super
        return result unless result.nil?

        filename = File.join(@cache_directory, to_cache_name(name))
        return nil unless File.exist?(filename)

        ::JSON.parse(File.open(filename, 'rb:utf-8') { |f| f.read })
      end

      def persist(name, content_string)
        super

        filename = File.join(@cache_directory, to_cache_name(name))
        File.open(filename, 'wb:utf-8') { |f| f.write(content_string) }
      end

      private

      def to_cache_name(name)
        ::Digest::SHA256.hexdigest(name) + '.txt'
      end
    end
  end
end
