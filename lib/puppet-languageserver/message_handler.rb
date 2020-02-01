# frozen_string_literal: true

require 'puppet_editor_services/handler/json_rpc'
require 'puppet_editor_services/protocol/json_rpc_messages'
require 'puppet-languageserver/server_capabilities'
require 'puppet-languageserver/client_session_state'
require 'puppet-languageserver/global_queues'

module PuppetLanguageServer
  # This module is just duck-typing the old PuppetLanguageServer::DocumentStore Module.
  # This will eventually be refactored out. But for now, this exists for backwards compatibility
  module DocumentStore
    def self.instance
      @instance ||= PuppetLanguageServer::SessionState::DocumentStore.new
    end

    def self.set_document(uri, content, doc_version)
      instance.set_document(uri, content, doc_version)
    end

    def self.remove_document(uri)
      instance.remove_document(uri)
    end

    def self.clear
      instance.clear
    end

    def self.document(uri, doc_version = nil)
      instance.document(uri, doc_version)
    end

    def self.document_version(uri)
      instance.document_version(uri)
    end

    def self.document_uris
      instance.document_uris
    end

    def self.document_type(uri)
      instance.document_type(uri)
    end

    def self.plan_file?(uri)
      instance.plan_file?(uri)
    end

    def self.initialize_store(options = {})
      instance.initialize_store(options)
    end

    def self.expire_store_information
      instance.expire_store_information
    end

    def self.store_root_path
      instance.store_root_path
    end

    def self.store_has_module_metadata?
      instance.store_has_module_metadata?
    end

    def self.store_has_environmentconf?
      instance.store_has_environmentconf?
    end
  end

  class MessageHandler < PuppetEditorServices::Handler::JsonRPC
    def initialize(*_)
      super
      @session_state = ClientSessionState.new(self, :documents => DocumentStore.instance, :object_cache => PuppetLanguageServer::PuppetHelper.cache)
    end

    def session_state # rubocop:disable Style/TrivialAccessors During the refactor, this is fine.
      @session_state
    end

    def language_client
      session_state.language_client
    end

    def documents
      session_state.documents
    end

    def request_initialize(_, json_rpc_message)
      PuppetLanguageServer.log_message(:debug, 'Received initialize method')

      language_client.parse_lsp_initialize!(json_rpc_message.params)
      # Setup static registrations if dynamic registration is not available
      info = {
        :documentOnTypeFormattingProvider => !language_client.client_capability('textDocument', 'onTypeFormatting', 'dynamicRegistration')
      }

      # Configure the document store
      documents.initialize_store(
        :workspace => workspace_root_from_initialize_params(json_rpc_message.params)
      )

      # Initiate loading the object_cache
      session_state.load_default_data!
      session_state.load_static_data!

      # Initiate loading of the workspace if needed
      session_state.load_workspace_data! if documents.store_has_module_metadata? || documents.store_has_environmentconf?

      { 'capabilities' => PuppetLanguageServer::ServerCapabilites.capabilities(info) }
    end

    def request_shutdown(_, _json_rpc_message)
      PuppetLanguageServer.log_message(:debug, 'Received shutdown method')
      nil
    end

    def request_puppet_getversion(_, _json_rpc_message)
      LSP::PuppetVersion.new(
        'languageServerVersion' => PuppetEditorServices.version,
        'puppetVersion'         => Puppet.version,
        'facterVersion'         => Facter.version,
        'factsLoaded'           => session_state.facts_loaded?,
        'functionsLoaded'       => session_state.default_functions_loaded?,
        'typesLoaded'           => session_state.default_types_loaded?,
        'classesLoaded'         => session_state.default_classes_loaded?
      )
    end

    def request_puppet_getresource(_, json_rpc_message)
      type_name = json_rpc_message.params['typename']
      title = json_rpc_message.params['title']
      return LSP::PuppetResourceResponse.new('error' => 'Missing Typename') if type_name.nil?

      resource_list = PuppetLanguageServer::PuppetHelper.get_puppet_resource(session_state, type_name, title, documents.store_root_path)
      return LSP::PuppetResourceResponse.new('data' => '') if resource_list.nil? || resource_list.length.zero?

      content = resource_list.map(&:manifest).join("\n\n") + "\n"
      LSP::PuppetResourceResponse.new('data' => content)
    end

    def request_puppet_compilenodegraph(_, json_rpc_message)
      file_uri = json_rpc_message.params['external']
      return LSP::PuppetNodeGraphResponse.new('error' => 'Files of this type can not be used to create a node graph.') unless documents.document_type(file_uri) == :manifest
      document = documents.document(file_uri)

      begin
        node_graph = PuppetLanguageServer::PuppetHelper.get_node_graph(session_state, document.content, documents.store_root_path)
        LSP::PuppetNodeGraphResponse.new('vertices' => node_graph.vertices,
                                         'edges'    => node_graph.edges,
                                         'error'    => node_graph.error_content)
      rescue StandardError => e
        PuppetLanguageServer.log_message(:error, "(puppet/compileNodeGraph) Error generating node graph. #{e}")
        LSP::PuppetNodeGraphResponse.new('error' => 'An internal error occured while generating the the node graph. Please see the debug log files for more information.')
      end
    end

    def request_puppet_fixdiagnosticerrors(_, json_rpc_message)
      formatted_request = LSP::PuppetFixDiagnosticErrorsRequest.new(json_rpc_message.params)
      file_uri = formatted_request.documentUri
      content = documents.document(file_uri)

      case documents.document_type(file_uri)
      when :manifest
        changes, new_content = PuppetLanguageServer::Manifest::ValidationProvider.fix_validate_errors(content)
      else
        raise "Unable to fixDiagnosticErrors on #{file_uri}"
      end

      LSP::PuppetFixDiagnosticErrorsResponse.new(
        'documentUri'  => formatted_request.documentUri,
        'fixesApplied' => changes,
        'newContent'   => changes > 0 || formatted_request.alwaysReturnContent ? new_content : nil
      )
    rescue StandardError => e
      PuppetLanguageServer.log_message(:error, "(puppet/fixDiagnosticErrors) #{e}")
      unless formatted_request.nil?
        LSP::PuppetFixDiagnosticErrorsResponse.new(
          'documentUri'  => formatted_request.documentUri,
          'fixesApplied' => 0,
          'newContent'   => formatted_request.alwaysReturnContent ? content : nil # rubocop:disable Metrics/BlockNesting
        )
      end
    end

    def request_textdocument_completion(_, json_rpc_message)
      file_uri = json_rpc_message.params['textDocument']['uri']
      line_num = json_rpc_message.params['position']['line']
      char_num = json_rpc_message.params['position']['character']
      content = documents.document(file_uri)
      context = json_rpc_message.params['context'].nil? ? nil : LSP::CompletionContext.new(json_rpc_message.params['context'])

      case documents.document_type(file_uri)
      when :manifest
        PuppetLanguageServer::Manifest::CompletionProvider.complete(session_state, content, line_num, char_num, :context => context, :tasks_mode => documents.plan_file?(file_uri))
      else
        raise "Unable to provide completion on #{file_uri}"
      end
    rescue StandardError => e
      PuppetLanguageServer.log_message(:error, "(textDocument/completion) #{e}")
      LSP::CompletionList.new('isIncomplete' => false, 'items' => [])
    end

    def request_completionitem_resolve(_, json_rpc_message)
      PuppetLanguageServer::Manifest::CompletionProvider.resolve(session_state, LSP::CompletionItem.new(json_rpc_message.params))
    rescue StandardError => e
      PuppetLanguageServer.log_message(:error, "(completionItem/resolve) #{e}")
      # Spit back the same params if an error happens
      json_rpc_message.params
    end

    def request_textdocument_hover(_, json_rpc_message)
      file_uri = json_rpc_message.params['textDocument']['uri']
      line_num = json_rpc_message.params['position']['line']
      char_num = json_rpc_message.params['position']['character']
      content = documents.document(file_uri)
      case documents.document_type(file_uri)
      when :manifest
        PuppetLanguageServer::Manifest::HoverProvider.resolve(session_state, content, line_num, char_num, :tasks_mode => documents.plan_file?(file_uri))
      else
        raise "Unable to provide hover on #{file_uri}"
      end
    rescue StandardError => e
      PuppetLanguageServer.log_message(:error, "(textDocument/hover) #{e}")
      LSP::Hover.new
    end

    def request_textdocument_definition(_, json_rpc_message)
      file_uri = json_rpc_message.params['textDocument']['uri']
      line_num = json_rpc_message.params['position']['line']
      char_num = json_rpc_message.params['position']['character']
      content = documents.document(file_uri)

      case documents.document_type(file_uri)
      when :manifest
        PuppetLanguageServer::Manifest::DefinitionProvider.find_definition(session_state, content, line_num, char_num, :tasks_mode => documents.plan_file?(file_uri))
      else
        raise "Unable to provide definition on #{file_uri}"
      end
    rescue StandardError => e
      PuppetLanguageServer.log_message(:error, "(textDocument/definition) #{e}")
      nil
    end

    def request_textdocument_documentsymbol(_, json_rpc_message)
      file_uri = json_rpc_message.params['textDocument']['uri']
      content  = documents.document(file_uri)

      case documents.document_type(file_uri)
      when :manifest
        PuppetLanguageServer::Manifest::DocumentSymbolProvider.extract_document_symbols(content, :tasks_mode => documents.plan_file?(file_uri))
      else
        raise "Unable to provide definition on #{file_uri}"
      end
    rescue StandardError => e
      PuppetLanguageServer.log_message(:error, "(textDocument/documentSymbol) #{e}")
      nil
    end

    def request_textdocument_ontypeformatting(_, json_rpc_message)
      return nil unless language_client.format_on_type
      file_uri = json_rpc_message.params['textDocument']['uri']
      line_num = json_rpc_message.params['position']['line']
      char_num = json_rpc_message.params['position']['character']
      content  = documents.document(file_uri)

      case documents.document_type(file_uri)
      when :manifest
        PuppetLanguageServer::Manifest::FormatOnTypeProvider.instance.format(
          content,
          line_num,
          char_num,
          json_rpc_message.params['ch'],
          json_rpc_message.params['options']
        )
      else
        raise "Unable to format on type on #{file_uri}"
      end
    rescue StandardError => e
      PuppetLanguageServer.log_message(:error, "(textDocument/onTypeFormatting) #{e}")
      nil
    end

    def request_textdocument_signaturehelp(_, json_rpc_message)
      file_uri = json_rpc_message.params['textDocument']['uri']
      line_num = json_rpc_message.params['position']['line']
      char_num = json_rpc_message.params['position']['character']
      content  = documents.document(file_uri)

      case documents.document_type(file_uri)
      when :manifest
        PuppetLanguageServer::Manifest::SignatureProvider.signature_help(
          session_state,
          content,
          line_num,
          char_num,
          :tasks_mode => documents.plan_file?(file_uri)
        )
      else
        raise "Unable to provide signatures on #{file_uri}"
      end
    rescue StandardError => e
      PuppetLanguageServer.log_message(:error, "(textDocument/signatureHelp) #{e}")
      nil
    end

    def request_workspace_symbol(_, json_rpc_message)
      result = []
      result.concat(PuppetLanguageServer::Manifest::DocumentSymbolProvider.workspace_symbols(json_rpc_message.params['query'], PuppetLanguageServer::PuppetHelper.cache))
      result
    rescue StandardError => e
      PuppetLanguageServer.log_message(:error, "(workspace/symbol) #{e}")
      []
    end

    def notification_initialized(_, _json_rpc_message)
      PuppetLanguageServer.log_message(:info, 'Client has received initialization')
      # Raise a warning if the Puppet version is mismatched
      server_options = protocol.connection.server.server_options
      unless server_options[:puppet_version].nil? || server_options[:puppet_version] == Puppet.version
        json_rpc_handler.send_show_message_notification(
          LSP::MessageType::WARNING,
          "Unable to use Puppet version '#{server_options[:puppet_version]}' as it is not available. Using version '#{Puppet.version}' instead."
        )
      end
      # Register for workspace setting changes if it's supported
      if language_client.client_capability('workspace', 'didChangeConfiguration', 'dynamicRegistration') == true
        language_client.register_capability('workspace/didChangeConfiguration')
      else
        PuppetLanguageServer.log_message(:debug, 'Client does not support didChangeConfiguration dynamic registration. Using push method for configuration change detection.')
      end
    end

    def notification_exit(_, _json_rpc_message)
      PuppetLanguageServer.log_message(:info, 'Received exit notification.  Closing connection to client...')
      protocol.connection.close
    end

    def notification_textdocument_didopen(client_handler_id, json_rpc_message)
      PuppetLanguageServer.log_message(:info, 'Received textDocument/didOpen notification.')
      file_uri = json_rpc_message.params['textDocument']['uri']
      content = json_rpc_message.params['textDocument']['text']
      doc_version = json_rpc_message.params['textDocument']['version']
      documents.set_document(file_uri, content, doc_version)
      enqueue_validation(file_uri, doc_version, client_handler_id)
    end

    def notification_textdocument_didclose(_, json_rpc_message)
      PuppetLanguageServer.log_message(:info, 'Received textDocument/didClose notification.')
      file_uri = json_rpc_message.params['textDocument']['uri']
      documents.remove_document(file_uri)
    end

    def notification_textdocument_didchange(client_handler_id, json_rpc_message)
      PuppetLanguageServer.log_message(:info, 'Received textDocument/didChange notification.')
      file_uri = json_rpc_message.params['textDocument']['uri']
      content = json_rpc_message.params['contentChanges'][0]['text'] # TODO: Bad hardcoding zero
      doc_version = json_rpc_message.params['textDocument']['version']
      documents.set_document(file_uri, content, doc_version)
      enqueue_validation(file_uri, doc_version, client_handler_id)
    end

    def notification_textdocument_didsave(_, _json_rpc_message)
      PuppetLanguageServer.log_message(:info, 'Received textDocument/didSave notification.')
      # Expire the store cache so that the store information can re-evaluated
      documents.expire_store_information
      if documents.store_has_module_metadata? || documents.store_has_environmentconf?
        # Load the workspace information
        session_state.load_workspace_data!
      else
        # Purge the workspace information
        session_state.purge_workspace_data!
      end
    end

    def notification_workspace_didchangeconfiguration(_, json_rpc_message)
      if json_rpc_message.params.key?('settings') && json_rpc_message.params['settings'].nil?
        # This is a notification from a dynamic registration. Need to send a workspace/configuration
        # request to get the actual configuration
        language_client.send_configuration_request
      else
        language_client.parse_lsp_configuration_settings!(json_rpc_message.params['settings'])
      end
    end

    def response_client_registercapability(_, json_rpc_message, original_request)
      language_client.parse_register_capability_response!(json_rpc_message, original_request)
    end

    def response_client_unregistercapability(_, json_rpc_message, original_request)
      language_client.parse_unregister_capability_response!(json_rpc_message, original_request)
    end

    def response_workspace_configuration(_, json_rpc_message, original_request)
      return unless json_rpc_message.is_successful
      original_request.params.items.each_with_index do |item, index|
        # The response from the client strips the section name so we need to re-add it
        language_client.parse_lsp_configuration_settings!(item.section => json_rpc_message.result[index])
      end
    end

    def unhandled_exception(error, options)
      super(error, options)
      PuppetLanguageServer::CrashDump.write_crash_file(error, session_state, nil, options)
    end

    private

    def enqueue_validation(file_uri, doc_version, client_handler_id)
      options = {}
      if documents.document_type(file_uri) == :puppetfile
        options[:resolve_puppetfile] = language_client.use_puppetfile_resolver
        options[:puppet_version]     = Puppet.version
        options[:module_path]        = PuppetLanguageServer::PuppetHelper.module_path
      end
      GlobalQueues.validate_queue.enqueue(file_uri, doc_version, client_handler_id, options)
    end

    def workspace_root_from_initialize_params(params)
      if params.key?('workspaceFolders')
        return nil if params['workspaceFolders'].nil? || params['workspaceFolders'].empty?
        # We don't support multiple workspace folders yet, so just select the first one
        return UriHelper.uri_path(params['workspaceFolders'][0]['uri'])
      end
      return UriHelper.uri_path(params['rootUri']) if params.key?('rootUri')
      params['rootPath']
    end
  end

  class DisabledMessageHandler < PuppetEditorServices::Handler::JsonRPC
    def request_initialize(_, _json_rpc_message)
      PuppetLanguageServer.log_message(:debug, 'Received initialize method')
      # If the Language Server is not active then we can not respond to any capability
      { 'capabilities' => PuppetLanguageServer::ServerCapabilites.no_capabilities }
    end

    def request_shutdown(_, _json_rpc_message)
      PuppetLanguageServer.log_message(:debug, 'Received shutdown method')
      nil
    end

    def request_puppet_getversion(_, _json_rpc_message)
      # Clients may use the getVersion request to figure out when the server has "finished" loading. In this
      # case just fake the response that we are fully loaded with unknown gem versions
      LSP::PuppetVersion.new(
        'languageServerVersion' => PuppetEditorServices.version,
        'puppetVersion'         => 'Unknown',
        'facterVersion'         => 'Unknown',
        'factsLoaded'           => true,
        'functionsLoaded'       => true,
        'typesLoaded'           => true,
        'classesLoaded'         => true
      )
    end

    def notification_initialized(_, _json_rpc_message)
      PuppetLanguageServer.log_message(:info, 'Client has received initialization')

      protocol.encode_and_send(
        ::PuppetEditorServices::Protocol::JsonRPCMessages.new_notification(
          'window/showMessage',
          'type'    => LSP::MessageType::WARNING,
          'message' => 'An error occured while starting the Language Server. The server has been disabled.'
        )
      )
    end

    def notification_exit(_, _json_rpc_message)
      PuppetLanguageServer.log_message(:info, 'Received exit notification.  Closing connection to client...')
      protocol.close_connection
    end
  end
end
