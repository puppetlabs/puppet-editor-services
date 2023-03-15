# frozen_string_literal: true

require 'molinillo'

module PuppetfileResolver
  module UI
    class NullUI
      include Molinillo::UI

      # Suppress all output
      def output
        @output ||= File.open(File::NULL, 'w')
      end

      def debug?
        false
      end
    end
  end
end
