module PuppetLanguageServerSidecar
  module Cache
    CLASSES_SECTION = 'classes'.freeze
    FUNCTIONS_SECTION = 'functions'.freeze
    TYPES_SECTION = 'types'.freeze

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
    end
  end
end
