# frozen_string_literal: true

require 'yard/logging'
module YARD
  class Logger < ::Logger
    # Suppress ANY output
    def self.instance(_pipe = STDOUT)
      @logger ||= new(nil)
    end

    # Suppress ANY progress indicators
    def show_progress
      false
    end
  end
end
