# frozen_string_literal: true

require 'molinillo'

module PuppetfileResolver
  module UI
    class DebugUI
      include Molinillo::UI

      def debug?
        true
      end
    end
  end
end
