# frozen_string_literal: true

module PuppetLanguageServerSidecar
  module Cache
    CLASSES_SECTION = 'classes'
    FUNCTIONS_SECTION = 'functions'
    TYPES_SECTION = 'types'
    PUPPETSTRINGS_SECTION = 'puppetstrings'

    class Base
      attr_reader :cache_options

      def initialize(options = {})
        @cache_options = options
      end

      def active?
        false
      end

      def load(_absolute_path, _section)
        raise NotImplementedError
      end

      def save(_absolute_path, _section, _content_string)
        raise NotImplementedError
      end

      # WARNING - This method is only intended for testing the cache
      # and should not be used for normal operations
      def clear!
        raise NotImplementedError
      end
    end
  end
end
