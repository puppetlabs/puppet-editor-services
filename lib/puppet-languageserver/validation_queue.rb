# frozen_string_literal: true

module PuppetLanguageServer
  # Module for enqueing and running document level validation asynchronously
  # When adding a document to be validation, it will remove any validation requests for the same
  # document in the queue so that only the latest document needs to be processed.
  #
  # It will also ignore sending back validation results to the client if the document is
  # updated during the validation process
  module ValidationQueue
    @queue = []
    @queue_mutex = Mutex.new
    @queue_thread = nil

    # Enqueue a file to be validated
    def self.enqueue(file_uri, doc_version, connection_id, options = {})
      document_type = PuppetLanguageServer::DocumentStore.document_type(file_uri)

      unless %i[manifest epp puppetfile].include?(document_type)
        # Can't validate these types so just emit an empty validation result
        send_diagnostics(connection_id, file_uri, [])
        return
      end

      @queue_mutex.synchronize do
        @queue.reject! { |item| item['file_uri'] == file_uri }

        @queue << {
          'file_uri'      => file_uri,
          'doc_version'   => doc_version,
          'document_type' => document_type,
          'connection_id' => connection_id,
          'options'       => options
        }
      end

      if @queue_thread.nil? || !@queue_thread.alive?
        @queue_thread = Thread.new do
          begin
            worker
          rescue => e # rubocop:disable Style/RescueStandardError
            PuppetLanguageServer.log_message(:error, "Error in ValidationQueue Thread: #{e}")
            raise
          end
        end
      end

      nil
    end

    # Synchronously validate a file
    def self.validate_sync(file_uri, doc_version, connection_id, options = {})
      document_type = PuppetLanguageServer::DocumentStore.document_type(file_uri)
      content = documents.document(file_uri, doc_version)
      return nil if content.nil?
      result = validate(file_uri, document_type, content, options)

      # Send the response
      send_diagnostics(connection_id, file_uri, result)
    end

    # Helper method to the Document Store
    def self.documents
      PuppetLanguageServer::DocumentStore
    end

    # Wait for the queue to become empty
    def self.drain_queue
      return if @queue_thread.nil? || !@queue_thread.alive?
      @queue_thread.join
      nil
    end

    # Testing helper resets the queue and prepopulates it with
    # a known arbitrary configuration.
    # ONLY USE THIS FOR TESTING!
    def self.reset_queue(initial_state = [])
      @queue_mutex.synchronize do
        @queue = initial_state
      end
    end

    def self.send_diagnostics(connection_id, file_uri, diagnostics)
      connection = PuppetEditorServices::Server.current_server.connection(connection_id)
      return if connection.nil?

      connection.protocol.encode_and_send(
        ::PuppetEditorServices::Protocol::JsonRPCMessages.new_notification('textDocument/publishDiagnostics', 'uri' => file_uri, 'diagnostics' => diagnostics)
      )
    end
    private_class_method :send_diagnostics

    # Validate a document
    def self.validate(document_uri, document_type, content, options = {})
      options = {} if options.nil?
      # Perform validation
      case document_type
      when :manifest
        options[:tasks_mode] = PuppetLanguageServer::DocumentStore.plan_file?(document_uri)
        PuppetLanguageServer::Manifest::ValidationProvider.validate(content, options)
      when :epp
        PuppetLanguageServer::Epp::ValidationProvider.validate(content)
      when :puppetfile
        options[:document_uri] = document_uri
        PuppetLanguageServer::Puppetfile::ValidationProvider.validate(content, options)
      else
        []
      end
    end
    private_class_method :validate

    # Thread worker which processes all jobs in the queue and validates each document
    # serially
    def self.worker
      work_item = nil
      loop do
        @queue_mutex.synchronize do
          return if @queue.empty?
          work_item = @queue.shift
        end
        return if work_item.nil?

        file_uri           = work_item['file_uri']
        doc_version        = work_item['doc_version']
        connection_id      = work_item['connection_id']
        document_type      = work_item['document_type']
        validation_options = work_item['options']

        # Check if the document is the latest version
        content = documents.document(file_uri, doc_version)
        if content.nil?
          PuppetLanguageServer.log_message(:debug, "ValidationQueue Thread: Ignoring #{work_item['file_uri']} as it is not the latest version or has been removed")
          return
        end

        # Perform validation
        result = validate(file_uri, document_type, content, validation_options)

        # Check if the document is still latest version
        current_version = documents.document_version(file_uri)
        if current_version != doc_version
          PuppetLanguageServer.log_message(:debug, "ValidationQueue Thread: Ignoring #{work_item['file_uri']} as has changed version from #{doc_version} to #{current_version}")
          return
        end

        # Send the response
        send_diagnostics(connection_id, file_uri, result)
      end
    end
    private_class_method :worker
  end
end
