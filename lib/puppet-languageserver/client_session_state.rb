# frozen_string_literal: true

require 'puppet-languageserver/session_state/document_store'
require 'puppet-languageserver/session_state/language_client'
require 'puppet-languageserver/session_state/object_cache'

module PuppetLanguageServer
  class ClientSessionState
    attr_reader :documents

    attr_reader :language_client

    attr_reader :object_cache

    def initialize(message_handler, options = {})
      @documents       = options[:documents].nil? ? PuppetLanguageServer::SessionState::DocumentStore.new : options[:documents]
      @language_client = options[:language_client].nil? ? PuppetLanguageServer::SessionState::LanguageClient.new(message_handler) : options[:language_client]
      @object_cache    = options[:object_cache].nil? ? PuppetLanguageServer::SessionState::ObjectCache.new : options[:object_cache]
    end
  end
end
