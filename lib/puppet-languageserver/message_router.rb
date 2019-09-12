# frozen_string_literal: true

module PuppetLanguageServer
  class BaseMessageRouter
    attr_accessor :json_rpc_handler

    def initialize(*_); end

    def receive_request(request)
      if request.rpc_method.start_with?('$/')
        json_rpc_handler.reply_error nil, PuppetLanguageServer::CODE_METHOD_NOT_FOUND, PuppetLanguageServer::MSG_METHOD_NOT_FOUND
      else
        PuppetLanguageServer.log_message(:error, "Unknown RPC method #{request.rpc_method}")
      end
    end

    def receive_notification(method, _params)
      if method.start_with?('$/')
        PuppetLanguageServer.log_message(:debug, "Ignoring RPC notification #{method}")
      else
        PuppetLanguageServer.log_message(:error, "Unknown RPC notification #{method}")
      end
    end

    def receive_response(_response, _original_request); end
  end

  class MessageRouter < BaseMessageRouter
    attr_reader :server_options

    def initialize(options = {})
      super
      @server_options = options.nil? ? {} : options
    end

    def documents
      PuppetLanguageServer::DocumentStore
    end

    def receive_request(request)
      case request.rpc_method
      when 'initialize'
        PuppetLanguageServer.log_message(:debug, 'Received initialize method')
        request.reply_result('capabilities' => PuppetLanguageServer::ServerCapabilites.capabilities)
        unless server_options[:puppet_version].nil? || server_options[:puppet_version] == Puppet.version
          # Add a minor delay before sending the notification to give the client some processing time
          sleep(0.5)
          json_rpc_handler.send_show_message_notification(
            LSP::MessageType::WARNING,
            "Unable to use Puppet version '#{server_options[:puppet_version]}' as it is not available. Using version '#{Puppet.version}' instead."
          )
        end

      when 'shutdown'
        PuppetLanguageServer.log_message(:debug, 'Received shutdown method')
        request.reply_result(nil)

      when 'puppet/getVersion'
        request.reply_result(LSP::PuppetVersion.new(
                               'languageServerVersion' => PuppetEditorServices.version,
                               'puppetVersion'         => Puppet.version,
                               'facterVersion'         => Facter.version,
                               'factsLoaded'           => PuppetLanguageServer::FacterHelper.facts_loaded?,
                               'functionsLoaded'       => PuppetLanguageServer::PuppetHelper.default_functions_loaded?,
                               'typesLoaded'           => PuppetLanguageServer::PuppetHelper.default_types_loaded?,
                               'classesLoaded'         => PuppetLanguageServer::PuppetHelper.default_classes_loaded?
                             ))

      when 'puppet/getResource'
        type_name = request.params['typename']
        title = request.params['title']
        if type_name.nil?
          request.reply_result(LSP::PuppetResourceResponse.new('error' => 'Missing Typename'))
          return
        end
        resource_list = PuppetLanguageServer::PuppetHelper.get_puppet_resource(type_name, title, documents.store_root_path)
        if resource_list.nil? || resource_list.length.zero?
          request.reply_result(LSP::PuppetResourceResponse.new('data' => ''))
          return
        end
        content = resource_list.map(&:manifest).join("\n\n") + "\n"
        request.reply_result(LSP::PuppetResourceResponse.new('data' => content))

      when 'puppet/compileNodeGraph'
        file_uri = request.params['external']
        unless documents.document_type(file_uri) == :manifest
          request.reply_result(LSP::CompileNodeGraphResponse.new('error' => 'Files of this type can not be used to create a node graph.'))
          return
        end
        content = documents.document(file_uri)

        begin
          node_graph = PuppetLanguageServer::PuppetHelper.get_node_graph(content, documents.store_root_path)
          request.reply_result(LSP::CompileNodeGraphResponse.new('dotContent' => node_graph.dot_content,
                                                                 'error'      => node_graph.error_content))
        rescue StandardError => e
          PuppetLanguageServer.log_message(:error, "(puppet/compileNodeGraph) Error generating node graph. #{e}")
          request.reply_result(LSP::CompileNodeGraphResponse.new('error' => 'An internal error occured while generating the the node graph. Please see the debug log files for more information.'))
        end

      when 'puppet/fixDiagnosticErrors'
        begin
          formatted_request = LSP::PuppetFixDiagnosticErrorsRequest.new(request.params)
          file_uri = formatted_request.documentUri
          content = documents.document(file_uri)

          case documents.document_type(file_uri)
          when :manifest
            changes, new_content = PuppetLanguageServer::Manifest::ValidationProvider.fix_validate_errors(content)
          else
            raise "Unable to fixDiagnosticErrors on #{file_uri}"
          end

          request.reply_result(LSP::PuppetFixDiagnosticErrorsResponse.new(
                                 'documentUri'  => formatted_request.documentUri,
                                 'fixesApplied' => changes,
                                 'newContent'   => changes > 0 || formatted_request.alwaysReturnContent ? new_content : nil
                               ))
        rescue StandardError => e
          PuppetLanguageServer.log_message(:error, "(puppet/fixDiagnosticErrors) #{e}")
          unless formatted_request.nil?
            request.reply_result(LSP::PuppetFixDiagnosticErrorsResponse.new(
                                   'documentUri'  => formatted_request.documentUri,
                                   'fixesApplied' => 0,
                                   'newContent'   => formatted_request.alwaysReturnContent ? content : nil # rubocop:disable Metrics/BlockNesting
                                 ))
          end
        end

      when 'textDocument/completion'
        file_uri = request.params['textDocument']['uri']
        line_num = request.params['position']['line']
        char_num = request.params['position']['character']
        content = documents.document(file_uri)
        begin
          case documents.document_type(file_uri)
          when :manifest
            request.reply_result(PuppetLanguageServer::Manifest::CompletionProvider.complete(content, line_num, char_num, :tasks_mode => PuppetLanguageServer::DocumentStore.plan_file?(file_uri)))
          else
            raise "Unable to provide completion on #{file_uri}"
          end
        rescue StandardError => e
          PuppetLanguageServer.log_message(:error, "(textDocument/completion) #{e}")
          request.reply_result(LSP::CompletionList.new('isIncomplete' => false, 'items' => []))
        end

      when 'completionItem/resolve'
        begin
          request.reply_result(PuppetLanguageServer::Manifest::CompletionProvider.resolve(
                                 LSP::CompletionItem.new(request.params)
                               ))
        rescue StandardError => e
          PuppetLanguageServer.log_message(:error, "(completionItem/resolve) #{e}")
          # Spit back the same params if an error happens
          request.reply_result(request.params)
        end

      when 'textDocument/hover'
        file_uri = request.params['textDocument']['uri']
        line_num = request.params['position']['line']
        char_num = request.params['position']['character']
        content = documents.document(file_uri)
        begin
          case documents.document_type(file_uri)
          when :manifest
            request.reply_result(PuppetLanguageServer::Manifest::HoverProvider.resolve(content, line_num, char_num, :tasks_mode => PuppetLanguageServer::DocumentStore.plan_file?(file_uri)))
          else
            raise "Unable to provide hover on #{file_uri}"
          end
        rescue StandardError => e
          PuppetLanguageServer.log_message(:error, "(textDocument/hover) #{e}")
          request.reply_result(LSP::Hover.new)
        end

      when 'textDocument/definition'
        file_uri = request.params['textDocument']['uri']
        line_num = request.params['position']['line']
        char_num = request.params['position']['character']
        content = documents.document(file_uri)
        begin
          case documents.document_type(file_uri)
          when :manifest
            request.reply_result(PuppetLanguageServer::Manifest::DefinitionProvider.find_definition(content, line_num, char_num, :tasks_mode => PuppetLanguageServer::DocumentStore.plan_file?(file_uri)))
          else
            raise "Unable to provide definition on #{file_uri}"
          end
        rescue StandardError => e
          PuppetLanguageServer.log_message(:error, "(textDocument/definition) #{e}")
          request.reply_result(nil)
        end

      when 'textDocument/documentSymbol'
        file_uri = request.params['textDocument']['uri']
        content  = documents.document(file_uri)
        begin
          case documents.document_type(file_uri)
          when :manifest
            request.reply_result(PuppetLanguageServer::Manifest::DocumentSymbolProvider.extract_document_symbols(content, :tasks_mode => PuppetLanguageServer::DocumentStore.plan_file?(file_uri)))
          else
            raise "Unable to provide definition on #{file_uri}"
          end
        rescue StandardError => e
          PuppetLanguageServer.log_message(:error, "(textDocument/documentSymbol) #{e}")
          request.reply_result(nil)
        end

      when 'textDocument/signatureHelp'
        file_uri = request.params['textDocument']['uri']
        line_num = request.params['position']['line']
        char_num = request.params['position']['character']
        content  = documents.document(file_uri)
        begin
          case documents.document_type(file_uri)
          when :manifest
            request.reply_result(PuppetLanguageServer::Manifest::SignatureProvider.signature_help(
                                   content,
                                   line_num,
                                   char_num,
                                   :tasks_mode => PuppetLanguageServer::DocumentStore.plan_file?(file_uri)
                                 ))
          else
            raise "Unable to provide signatures on #{file_uri}"
          end
        rescue StandardError => e
          PuppetLanguageServer.log_message(:error, "(textDocument/signatureHelp) #{e}")
          request.reply_result(nil)
        end

      when 'workspace/symbol'
        begin
          result = []
          result.concat(PuppetLanguageServer::Manifest::DocumentSymbolProvider.workspace_symbols(request.params['query'], PuppetLanguageServer::PuppetHelper.cache))
          request.reply_result(result)
        rescue StandardError => e
          PuppetLanguageServer.log_message(:error, "(workspace/symbol) #{e}")
          request.reply_result([])
        end

      else
        super
      end
    rescue StandardError => e
      PuppetLanguageServer::CrashDump.write_crash_file(e, nil, 'request' => request.rpc_method, 'params' => request.params)
      raise
    end

    def receive_notification(method, params)
      case method
      when 'initialized'
        PuppetLanguageServer.log_message(:info, 'Client has received initialization')

      when 'exit'
        PuppetLanguageServer.log_message(:info, 'Received exit notification.  Closing connection to client...')
        json_rpc_handler.close_connection

      when 'textDocument/didOpen'
        PuppetLanguageServer.log_message(:info, 'Received textDocument/didOpen notification.')
        file_uri = params['textDocument']['uri']
        content = params['textDocument']['text']
        doc_version = params['textDocument']['version']
        documents.set_document(file_uri, content, doc_version)
        PuppetLanguageServer::ValidationQueue.enqueue(file_uri, doc_version, json_rpc_handler)

      when 'textDocument/didClose'
        PuppetLanguageServer.log_message(:info, 'Received textDocument/didClose notification.')
        file_uri = params['textDocument']['uri']
        documents.remove_document(file_uri)

      when 'textDocument/didChange'
        PuppetLanguageServer.log_message(:info, 'Received textDocument/didChange notification.')
        file_uri = params['textDocument']['uri']
        content = params['contentChanges'][0]['text'] # TODO: Bad hardcoding zero
        doc_version = params['textDocument']['version']
        documents.set_document(file_uri, content, doc_version)
        PuppetLanguageServer::ValidationQueue.enqueue(file_uri, doc_version, json_rpc_handler)

      when 'textDocument/didSave'
        PuppetLanguageServer.log_message(:info, 'Received textDocument/didSave notification.')
        # Expire the store cache so that the store information can re-evaluated
        PuppetLanguageServer::DocumentStore.expire_store_information
        if PuppetLanguageServer::DocumentStore.store_has_module_metadata? || PuppetLanguageServer::DocumentStore.store_has_environmentconf?
          # Load the workspace information
          PuppetLanguageServer::PuppetHelper.load_workspace_async
        else
          # Purge the workspace information
          PuppetLanguageServer::PuppetHelper.purge_workspace
        end

      else
        super
      end
    rescue StandardError => e
      PuppetLanguageServer::CrashDump.write_crash_file(e, nil, 'notification' => method, 'params' => params)
      raise
    end

    def receive_response(response, original_request)
      super
    rescue StandardError => e
      PuppetLanguageServer::CrashDump.write_crash_file(e, nil, 'response' => response, 'original_request' => original_request)
      raise
    end
  end

  class DisabledMessageRouter < BaseMessageRouter
    def receive_request(request)
      case request.rpc_method
      when 'initialize'
        PuppetLanguageServer.log_message(:debug, 'Received initialize method')
        # If the Language Server is not active then we can not respond to any capability. We also
        # send a warning to the user telling them this
        request.reply_result('capabilities' => PuppetLanguageServer::ServerCapabilites.no_capabilities)
        # Add a minor delay before sending the notification to give the client some processing time
        sleep(0.5)
        json_rpc_handler.send_show_message_notification(
          LSP::MessageType::WARNING,
          'An error occured while the Language Server was starting. The server has been disabled.'
        )

      when 'shutdown'
        PuppetLanguageServer.log_message(:debug, 'Received shutdown method')
        request.reply_result(nil)

      when 'puppet/getVersion'
        # Clients may use the getVersion request to figure out when the server has "finished" loading. In this
        # case just fake the response that we are fully loaded with unknown gem versions
        request.reply_result(LSP::PuppetVersion.new(
                               'puppetVersion'   => 'Unknown',
                               'facterVersion'   => 'Unknown',
                               'factsLoaded'     => true,
                               'functionsLoaded' => true,
                               'typesLoaded'     => true,
                               'classesLoaded'   => true
                             ))

      else
        # For any request return an internal error.
        request.reply_internal_error('Puppet Language Server is not active')
        PuppetLanguageServer.log_message(:error, "Unknown RPC method #{request.rpc_method}")
      end
    rescue StandardError => e
      PuppetLanguageServer::CrashDump.write_crash_file(e, nil, 'request' => request.rpc_method, 'params' => request.params)
      raise
    end

    def receive_notification(method, params)
      case method
      when 'initialized'
        PuppetLanguageServer.log_message(:info, 'Client has received initialization')

      when 'exit'
        PuppetLanguageServer.log_message(:info, 'Received exit notification.  Closing connection to client...')
        json_rpc_handler.close_connection

      else
        super
      end
    rescue StandardError => e
      PuppetLanguageServer::CrashDump.write_crash_file(e, nil, 'notification' => method, 'params' => params)
      raise
    end
  end
end
