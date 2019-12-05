# frozen_string_literal: true

require 'puppet-languageserver/global_queues/single_instance_queue'
require 'puppet_editor_services/server'

module PuppetLanguageServer
  module GlobalQueues
    class ValidationQueueJob < SingleInstanceQueueJob
      attr_accessor :file_uri
      attr_accessor :doc_version
      attr_accessor :connection_id
      attr_accessor :options

      def initialize(file_uri, doc_version, connection_id, options = {})
        super
        @file_uri = file_uri
        @doc_version = doc_version
        @connection_id = connection_id
        @options = options
      end

      def key
        @file_uri
      end
    end

    # Class for enqueing and running document level validation asynchronously
    #
    # Uses a single instance queue so only the latest document needs to be processed.
    # It will also ignore sending back validation results to the client if the document is updated during the validation process
    class ValidationQueue < SingleInstanceQueue
      def max_queue_threads
        1
      end

      def job_class
        ValidationQueueJob
      end

      def execute_job(job_object)
        super(job_object)
        session_state = session_state_from_connection_id(job_object.connection_id)
        document_store = session_state.nil? ? nil : session_state.documents
        raise "Document store is not available for connection id #{job_object.connection_id}" if document_store.nil?

        # Check if the document is the latest version
        content = document_store.document(job_object.file_uri, job_object.doc_version)
        if content.nil?
          PuppetLanguageServer.log_message(:debug, "#{self.class.name}: Ignoring #{job_object.file_uri} as it is not the latest version or has been removed")
          return
        end

        # Perform validation
        options = job_object.options.dup
        results = case document_store.document_type(job_object.file_uri)
                  when :manifest
                    options[:tasks_mode] = document_store.plan_file?(job_object.file_uri)
                    PuppetLanguageServer:: Manifest::ValidationProvider.validate(session_state, content, options)
                  when :epp
                    PuppetLanguageServer::Epp::ValidationProvider.validate(content)
                  when :puppetfile
                    options[:document_uri] = job_object.file_uri
                    PuppetLanguageServer::Puppetfile::ValidationProvider.validate(content, options)
                  else
                    []
                  end

        # Because this may be asynchronous it's possible the user has edited the document while we're performing validation.
        # Check if the document is still latest version and ignore the results if it's no longer the latest
        current_version = document_store.document_version(job_object.file_uri)
        if current_version != job_object.doc_version
          PuppetLanguageServer.log_message(:debug, "ValidationQueue Thread: Ignoring #{job_object.file_uri} as has changed version from #{job_object.doc_version} to #{current_version}")
          return
        end

        # Send the response
        send_diagnostics(job_object.connection_id, job_object.file_uri, results)
      end

      private

      def session_state_from_connection_id(connection_id)
        connection = PuppetEditorServices::Server.current_server.connection(connection_id)
        return if connection.nil?
        handler = connection.protocol.handler
        handler.respond_to?(:session_state) ? handler.session_state : nil
      end

      def send_diagnostics(connection_id, file_uri, diagnostics)
        connection = PuppetEditorServices::Server.current_server.connection(connection_id)
        return if connection.nil?

        connection.protocol.encode_and_send(
          ::PuppetEditorServices::Protocol::JsonRPCMessages.new_notification('textDocument/publishDiagnostics', 'uri' => file_uri, 'diagnostics' => diagnostics)
        )
      end
    end
  end
end
