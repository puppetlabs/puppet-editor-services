# frozen_string_literal: true

require 'puppet-languageserver/global_queues/validation_queue'

module PuppetLanguageServer
  module GlobalQueues
    def self.validate_queue
      @validate_queue ||= ValidationQueue.new
    end
  end
end
