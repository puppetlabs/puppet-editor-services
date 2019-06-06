# frozen_string_literal: true

module PuppetLanguageServerSidecar
  module Cache
    class Null < Base
      def initialize(options = {})
        super
      end

      def active?
        false
      end

      def load(*)
        nil
      end

      def save(*)
        true
      end

      def clear!
        nil
      end
    end
  end
end
