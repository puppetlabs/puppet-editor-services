# frozen_string_literal: true

require 'puppet-languageserver/sidecar_protocol'

module PuppetLanguageServerSidecar
  module Protocol
    class PuppetNodeGraph < PuppetLanguageServer::Sidecar::Protocol::PuppetNodeGraph
      def set_error(message) # rubocop:disable Naming/AccessorMethodName
        self.error_content = message
        self.vertices = nil
        self.edges = nil
        self
      end
    end
  end
end
