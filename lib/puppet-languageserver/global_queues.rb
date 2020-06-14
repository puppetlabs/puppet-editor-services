# frozen_string_literal: true

require 'puppet-languageserver/global_queues/validation_queue'
require 'puppet-languageserver/global_queues/sidecar_queue'

module PuppetLanguageServer
  module GlobalQueues
    def self.validate_queue
      @validate_queue ||= ValidationQueue.new
    end

    def self.sidecar_queue
      @sidecar_queue ||= SidecarQueue.new
    end
  end
end
