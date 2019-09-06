require 'spec_helper'

describe 'message_router' do
  MANIFEST_FILENAME = 'file:///something.pp'
  PUPPETFILE_FILENAME = 'file:///Puppetfile'
  EPP_FILENAME = 'file:///something.epp'
  UNKNOWN_FILENAME = 'file:///I_do_not_work.exe'
  ERROR_CAUSING_FILE_CONTENT = "file_content which causes errros\n <%- Wee!\n class 'foo' {'"

  let(:subject_options) {}
  let(:subject) do
    result = PuppetLanguageServer::MessageRouter.new(subject_options)
    result.json_rpc_handler = MockJSONRPCHandler.new
    result
  end

  describe '#documents' do
    it 'should respond to documents method' do
      expect(subject).to respond_to(:documents)
    end
  end

  describe '#receive_request' do
    let(:request_connection) { MockJSONRPCHandler.new() }
    let(:request_rpc_method) { nil }
    let(:request_params) { {} }
    let(:request_id) { 0 }
    let(:request) do
      PuppetLanguageServer::JSONRPCHandler::Request.new(
        request_connection, request_id, request_rpc_method, request_params)
    end

    before(:each) do
      allow(PuppetLanguageServer).to receive(:log_message)
    end

    context 'given a request that raises an error' do
      let(:request_rpc_method) { 'puppet/getVersion' }
      before(:each) do
        expect(Puppet).to receive(:version).and_raise('MockError')
        allow(PuppetLanguageServer::CrashDump).to receive(:write_crash_file)
      end

      it 'should raise an error' do
        expect{ subject.receive_request(request) }.to raise_error(/MockError/)
      end

      it 'should call PuppetLanguageServer::CrashDump.write_crash_file' do
        expect(PuppetLanguageServer::CrashDump).to receive(:write_crash_file)
        expect{ subject.receive_request(request) }.to raise_error(/MockError/)
      end
    end

    context 'given a request that is protocol implementation dependant' do
      let(:request_rpc_method) { '$/MockRequest' }

      it 'should reply with an error' do
        expect(subject.json_rpc_handler).to receive(:reply_error).with(Object, PuppetLanguageServer::CODE_METHOD_NOT_FOUND, Object)
        subject.receive_request(request)
      end
    end

    # initialize - https://github.com/Microsoft/language-server-protocol/blob/master/protocol.md#initialize
    context 'given an initialize request' do
      let(:request_rpc_method) { 'initialize' }
      it 'should reply with capabilites' do
        expect(request).to receive(:reply_result).with(hash_including('capabilities'))

        subject.receive_request(request)
      end
    end

    # shutdown - https://github.com/Microsoft/language-server-protocol/blob/master/protocol.md#shutdown
    context 'given a shutdown request' do
      let(:request_rpc_method) { 'shutdown' }
      it 'should reply with nil' do
        expect(request).to receive(:reply_result).with(nil)

        subject.receive_request(request)
      end
    end

    context 'given a puppet/getVersion request' do
      let(:request_rpc_method) { 'puppet/getVersion' }
      it 'should reply with the Puppet Version' do
        expect(request).to receive(:reply_result).with(duck_type(:puppetVersion))

        subject.receive_request(request)
      end
      it 'should reply with the Facter Version' do
        expect(request).to receive(:reply_result).with(duck_type(:facterVersion))

        subject.receive_request(request)
      end
      it 'should reply with the Language Server version' do
        expect(request).to receive(:reply_result).with(duck_type(:languageServerVersion))

        subject.receive_request(request)
      end
      it 'should reply with whether the facts are loaded' do
        expect(request).to receive(:reply_result).with(duck_type(:factsLoaded))

        subject.receive_request(request)
      end
      it 'should reply with whether the functions are loaded' do
        expect(request).to receive(:reply_result).with(duck_type(:functionsLoaded))

        subject.receive_request(request)
      end
      it 'should reply with whether the types are loaded' do
        expect(request).to receive(:reply_result).with(duck_type(:typesLoaded))

        subject.receive_request(request)
      end
    end

    context 'given a puppet/getResource request' do
      let(:request_rpc_method) { 'puppet/getResource' }
      let(:type_name) { 'user' }
      let(:title) { 'alice' }

      context 'and missing the typename' do
        let(:request_params) { {} }
        it 'should return an error string' do
          expect(request).to receive(:reply_result).with(duck_type(:error))

          subject.receive_request(request)
        end
      end

      context 'and resource face returns nil' do
        let(:request_params) { {
          'typename' => type_name,
        } }

        it 'should return data with an empty string' do
          expect(PuppetLanguageServer::PuppetHelper).to receive(:get_puppet_resource).and_return(nil)
          expect(request).to receive(:reply_result).with(having_attributes(:data => ''))

          subject.receive_request(request)
        end
      end

      context 'and only given a typename' do
        let(:request_params) { {
          'typename' => type_name,
        } }
        let(:resource_response) {
          result = PuppetLanguageServer::Sidecar::Protocol::ResourceList.new()
          result << random_sidecar_resource(type_name)
          result << random_sidecar_resource(type_name)
        }

        context 'and resource face returns empty array' do
          it 'should return data with an empty string' do
            expect(PuppetLanguageServer::PuppetHelper).to receive(:get_puppet_resource).and_return([])
            expect(request).to receive(:reply_result).with(having_attributes(:data => ''))

            subject.receive_request(request)
          end
        end

        context 'and resource face returns array with at least 2 elements' do
          before(:each) do
            expect(PuppetLanguageServer::PuppetHelper).to receive(:get_puppet_resource).with(type_name, nil, Object).and_return(resource_response)
          end

          it 'should call get_puppet_resource' do
            subject.receive_request(request)
          end

          it 'should return data containing the type name' do
            expect(request).to receive(:reply_result).with(having_attributes(:data => /#{type_name}/))

            subject.receive_request(request)
          end
        end
      end

      context 'and given a typename and title' do
        let(:request_params) { {
          'typename' => type_name,
          'title' => title,
        } }
        let(:resource_response) {
          result = PuppetLanguageServer::Sidecar::Protocol::ResourceList.new()
          result << random_sidecar_resource(type_name, title)
        }

        context 'and resource face returns nil' do
          it 'should return data with an empty string' do
            expect(PuppetLanguageServer::PuppetHelper).to receive(:get_puppet_resource).and_return(nil)
            expect(request).to receive(:reply_result).with(having_attributes(:data => ''))

            subject.receive_request(request)
          end
        end

        context 'and resource face returns a resource' do
          before(:each) do
            expect(PuppetLanguageServer::PuppetHelper).to receive(:get_puppet_resource).with(type_name, title, Object).and_return(resource_response)
          end

          it 'should call resource_face_get_by_typename' do
            subject.receive_request(request)
          end

          it 'should return data containing the type name' do
            expect(request).to receive(:reply_result).with(having_attributes(:data => /#{type_name}/))

            subject.receive_request(request)
          end

          it 'should return data containing the title' do
            expect(request).to receive(:reply_result).with(having_attributes(:data => /#{title}/))

            subject.receive_request(request)
          end
        end
      end
    end

    context 'given a puppet/compileNodeGraph request' do
      let(:request_rpc_method) { 'puppet/compileNodeGraph' }
      let(:file_uri) { MANIFEST_FILENAME }
      let(:file_content) { 'some file content' }
      let(:dot_content) { 'some graph content' }
      let(:request_params) {{
        'external' => file_uri
      }}

      before(:each) do
        # Create fake document store
        subject.documents.clear
        subject.documents.set_document(file_uri,file_content, 0)
      end

      context 'and a file which is not a puppet manifest' do
        let(:file_uri) { UNKNOWN_FILENAME }

        it 'should reply with the error text' do
          expect(request).to receive(:reply_result).with(having_attributes(:error => /Files of this type/))

          subject.receive_request(request)
        end

        it 'should not reply with dotContent' do
          expect(request).to_not receive(:reply_result).with(having_attributes(:dotContent => /.+/))

          subject.receive_request(request)
        end
      end

      context 'and an error during generation of the node graph' do
        let(:mock_return) {
          value = PuppetLanguageServer::Sidecar::Protocol::NodeGraph.new()
          value.dot_content = ''
          value.error_content = 'MockError'
          value
        }

        before(:each) do
          expect(PuppetLanguageServer::PuppetHelper).to receive(:get_node_graph).with(file_content, Object).and_return(mock_return)
        end

        it 'should reply with the error text' do
          expect(request).to receive(:reply_result).with(having_attributes(:error => /MockError/))

          subject.receive_request(request)
        end

        it 'should not reply with dotContent' do
          expect(request).to receive(:reply_result).with(having_attributes(:dotContent => ''))

          subject.receive_request(request)
        end
      end

      context 'and successfully generate the node graph' do
        let(:mock_return) {
          value = PuppetLanguageServer::Sidecar::Protocol::NodeGraph.new()
          value.dot_content = 'success'
          value.error_content = ''
          value
        }

        before(:each) do
          expect(PuppetLanguageServer::PuppetHelper).to receive(:get_node_graph).with(file_content, Object).and_return(mock_return)
        end

        it 'should reply with dotContent' do
          expect(request).to receive(:reply_result).with(having_attributes(:dotContent => /success/))

          subject.receive_request(request)
        end

        it 'should not reply with error' do
          expect(request).to receive(:reply_result).with(having_attributes(:error => ''))

          subject.receive_request(request)
        end
      end
    end

    context 'given a puppet/fixDiagnosticErrors request' do
      let(:request_rpc_method) { 'puppet/fixDiagnosticErrors' }
      let(:file_uri) { MANIFEST_FILENAME }
      let(:return_content) { true }
      let(:file_content) { 'some file content' }
      let(:file_new_content) { 'some new file content' }
      let(:request_params) {{
        'documentUri' => file_uri,
        'alwaysReturnContent' => return_content
      }}

      before(:each) do
        # Create fake document store
        subject.documents.clear
        subject.documents.set_document(file_uri,file_content, 0)
      end

      context 'and a file which is not a puppet manifest' do
        let(:file_uri) { UNKNOWN_FILENAME }

        it 'should log an error message' do
          expect(PuppetLanguageServer).to receive(:log_message).with(:error,/Unable to fixDiagnosticErrors/)

          subject.receive_request(request)
        end

        it 'should reply with the document uri' do
          expect(request).to receive(:reply_result).with(having_attributes(:documentUri => file_uri))

          subject.receive_request(request)
        end

        it 'should reply with no fixes applied' do
          expect(request).to receive(:reply_result).with(having_attributes(:fixesApplied => 0))

          subject.receive_request(request)
        end

        context 'and return_content set to true' do
          let(:return_content) { true }

          it 'should reply with document content' do
            expect(request).to receive(:reply_result).with(having_attributes(:newContent => file_content))

            subject.receive_request(request)
          end
        end

        context 'and return_content set to false' do
          let(:return_content) { false }

          it 'should reply with no document content' do
            expect(request).to receive(:reply_result).with(having_attributes(:newContent => nil))

            subject.receive_request(request)
          end
        end
      end

      context 'for a puppet manifest file' do
        let(:file_uri) { MANIFEST_FILENAME }

        context 'and an error during fixing the validation' do
          before(:each) do
            expect(PuppetLanguageServer::Manifest::ValidationProvider).to receive(:fix_validate_errors).with(file_content).and_raise('MockError')
          end

          it 'should log an error message' do
            expect(PuppetLanguageServer).to receive(:log_message).with(:error,/MockError/)

            subject.receive_request(request)
          end

          it 'should reply with the document uri' do
            expect(request).to receive(:reply_result).with(having_attributes(:documentUri => file_uri))

            subject.receive_request(request)
          end

          it 'should reply with no fixes applied' do
            expect(request).to receive(:reply_result).with(having_attributes(:fixesApplied => 0))

            subject.receive_request(request)
          end

          context 'and return_content set to true' do
            let(:return_content) { true }

            it 'should reply with document content' do
              expect(request).to receive(:reply_result).with(having_attributes(:newContent => file_content))

              subject.receive_request(request)
            end
          end

          context 'and return_content set to false' do
            let(:return_content) { false }

            it 'should reply with no document content' do
              expect(request).to receive(:reply_result).with(having_attributes(:newContent => nil))

              subject.receive_request(request)
            end
          end
        end

        context 'and succesfully fixes one or more validation errors' do
          let(:applied_fixes) { 1 }

          before(:each) do
            expect(PuppetLanguageServer::Manifest::ValidationProvider).to receive(:fix_validate_errors).with(file_content).and_return([applied_fixes, file_new_content])
          end

          it 'should reply with the document uri' do
            expect(request).to receive(:reply_result).with(having_attributes(:documentUri => file_uri))

            subject.receive_request(request)
          end

          it 'should reply with the number of fixes applied' do
            expect(request).to receive(:reply_result).with(having_attributes(:fixesApplied => applied_fixes))

            subject.receive_request(request)
          end

          context 'and return_content set to true' do
            let(:return_content) { true }

            it 'should reply with document content' do
              expect(request).to receive(:reply_result).with(having_attributes(:newContent => file_new_content))

              subject.receive_request(request)
            end
          end

          context 'and return_content set to false' do
            let(:return_content) { false }

            it 'should reply with document content' do
              expect(request).to receive(:reply_result).with(having_attributes(:newContent => file_new_content))

              subject.receive_request(request)
            end
          end
        end

        context 'and succesfully fixes zero validation errors' do
          let(:applied_fixes) { 0 }

          before(:each) do
            expect(PuppetLanguageServer::Manifest::ValidationProvider).to receive(:fix_validate_errors).with(file_content).and_return([applied_fixes, file_content])
          end

          it 'should reply with the document uri' do
            expect(request).to receive(:reply_result).with(having_attributes(:documentUri => file_uri))

            subject.receive_request(request)
          end

          it 'should reply with the number of fixes applied' do
            expect(request).to receive(:reply_result).with(having_attributes(:fixesApplied => applied_fixes))

            subject.receive_request(request)
          end

          context 'and return_content set to true' do
            let(:return_content) { true }

            it 'should reply with document content' do
              expect(request).to receive(:reply_result).with(having_attributes(:newContent => file_content))

              subject.receive_request(request)
            end
          end

          context 'and return_content set to false' do
            let(:return_content) { false }

            it 'should reply with no document content' do
              expect(request).to receive(:reply_result).with(having_attributes(:newContent => nil))

              subject.receive_request(request)
            end
          end
        end
      end
    end

    # textDocument/completion - https://github.com/Microsoft/language-server-protocol/blob/master/protocol.md#completion-request
    context 'given a textDocument/completion request' do
      let(:request_rpc_method) { 'textDocument/completion' }
      let(:line_num) { 1 }
      let(:char_num) { 2 }
      let(:request_params) {{
        'textDocument' => {
          'uri' => file_uri
        },
        'position' => {
          'line' => line_num,
          'character' => char_num,
        },
      }}

      context 'for a file the server does not understand' do
        let(:file_uri) { UNKNOWN_FILENAME }

        it 'should log an error message' do
          expect(PuppetLanguageServer).to receive(:log_message).with(:error,/Unable to provide completion/)

          subject.receive_request(request)
        end

        it 'should reply with a complete, empty response' do
          expect(request).to receive(:reply_result).with(having_attributes(:isIncomplete => false, :items => []))

          subject.receive_request(request)
        end
      end

      context 'for a puppet manifest file' do
        let(:file_uri) { MANIFEST_FILENAME }
        it 'should call complete method on the Completion Provider' do
          expect(PuppetLanguageServer::Manifest::CompletionProvider).to receive(:complete).with(Object,line_num,char_num,{:tasks_mode=>false}).and_return('something')

          subject.receive_request(request)
        end

        it 'should set tasks_mode option if the file is Puppet plan file' do
          expect(PuppetLanguageServer::Manifest::CompletionProvider).to receive(:complete).with(Object,line_num,char_num,{:tasks_mode=>true}).and_return('something')
          allow(PuppetLanguageServer::DocumentStore).to receive(:plan_file?).and_return true

          subject.receive_request(request)
        end

        context 'and an error occurs during completion' do
          before(:each) do
            expect(PuppetLanguageServer::Manifest::CompletionProvider).to receive(:complete).and_raise('MockError')
          end

          it 'should log an error message' do
            expect(PuppetLanguageServer).to receive(:log_message).with(:error,/MockError/)

            subject.receive_request(request)
          end

          it 'should reply with a complete, empty response' do
            expect(request).to receive(:reply_result).with(having_attributes(:isIncomplete => false, :items => []))

            subject.receive_request(request)
          end
        end
      end
    end

    # completionItem/resolve - https://github.com/Microsoft/language-server-protocol/blob/gh-pages/specification.md#completion-item-resolve-request-leftwards_arrow_with_hook
    context 'given a completionItem/resolve request' do
      let(:request_rpc_method) { 'completionItem/resolve' }
      let(:request_params) {{
        'type' => 'keyword',
        'name' => 'class',
        'data' => '',
      }}

      it 'should call resolve method on the Completion Provider' do
        expect(PuppetLanguageServer::Manifest::CompletionProvider).to receive(:resolve).and_return('something')

        subject.receive_request(request)
      end

      context 'and an error occurs during resolution' do
        before(:each) do
          expect(PuppetLanguageServer::Manifest::CompletionProvider).to receive(:resolve).and_raise('MockError')
        end

        it 'should log an error message' do
          expect(PuppetLanguageServer).to receive(:log_message).with(:error,/MockError/)

          subject.receive_request(request)
        end

        it 'should reply with the same input params' do
          expect(request).to receive(:reply_result).with(request_params)

          subject.receive_request(request)
        end
      end
    end

    # textDocument/hover - https://github.com/Microsoft/language-server-protocol/blob/gh-pages/specification.md#hover-request-leftwards_arrow_with_hook
    context 'given a textDocument/hover request' do
      let(:request_rpc_method) { 'textDocument/hover' }
      let(:line_num) { 1 }
      let(:char_num) { 2 }
      let(:request_params) {{
        'textDocument' => {
          'uri' => file_uri
        },
        'position' => {
          'line' => line_num,
          'character' => char_num,
        },
      }}

      context 'for a file the server does not understand' do
        let(:file_uri) { UNKNOWN_FILENAME }

        it 'should log an error message' do
          expect(PuppetLanguageServer).to receive(:log_message).with(:error,/Unable to provide hover/)

          subject.receive_request(request)
        end

        it 'should reply with nil for the contents' do
          expect(request).to receive(:reply_result).with(having_attributes(:contents => nil))

          subject.receive_request(request)
        end
      end

      context 'for a puppet manifest file' do
        let(:file_uri) { MANIFEST_FILENAME }

        it 'should call resolve method on the Hover Provider' do
          expect(PuppetLanguageServer::Manifest::HoverProvider).to receive(:resolve).with(Object,line_num,char_num,{:tasks_mode=>false}).and_return('something')

          subject.receive_request(request)
        end

        it 'should set tasks_mode option if the file is Puppet plan file' do
          expect(PuppetLanguageServer::Manifest::HoverProvider).to receive(:resolve).with(Object,line_num,char_num,{:tasks_mode=>true}).and_return('something')
          allow(PuppetLanguageServer::DocumentStore).to receive(:plan_file?).and_return true

          subject.receive_request(request)
        end

        context 'and an error occurs during resolution' do
          before(:each) do
            expect(PuppetLanguageServer::Manifest::HoverProvider).to receive(:resolve).and_raise('MockError')
          end

          it 'should log an error message' do
            expect(PuppetLanguageServer).to receive(:log_message).with(:error,/MockError/)

            subject.receive_request(request)
          end

          it 'should reply with nil for the contents' do
            expect(request).to receive(:reply_result).with(having_attributes(:contents => nil))

            subject.receive_request(request)
          end
        end
      end
    end

    # textDocument/definition - https://github.com/Microsoft/language-server-protocol/blob/gh-pages/specification.md#goto-definition-request-leftwards_arrow_with_hook
    context 'given a textDocument/definition request' do
      let(:request_rpc_method) { 'textDocument/definition' }
      let(:line_num) { 1 }
      let(:char_num) { 2 }
      let(:request_params) {{
        'textDocument' => {
          'uri' => file_uri
        },
        'position' => {
          'line' => line_num,
          'character' => char_num,
        },
      }}

      context 'for a file the server does not understand' do
        let(:file_uri) { UNKNOWN_FILENAME }

        it 'should log an error message' do
          expect(PuppetLanguageServer).to receive(:log_message).with(:error,/Unable to provide definition/)

          subject.receive_request(request)
        end

        it 'should reply with nil' do
          expect(request).to receive(:reply_result).with(nil)

          subject.receive_request(request)
        end
      end

      context 'for a puppet manifest file' do
        let(:file_uri) { MANIFEST_FILENAME }

        it 'should call find_definition method on the Definition Provider' do
          expect(PuppetLanguageServer::Manifest::DefinitionProvider).to receive(:find_definition)
            .with(Object,line_num,char_num,{:tasks_mode=>false}).and_return('something')

          subject.receive_request(request)
        end

        it 'should set tasks_mode option if the file is Puppet plan file' do
          expect(PuppetLanguageServer::Manifest::DefinitionProvider).to receive(:find_definition)
            .with(Object,line_num,char_num,{:tasks_mode=>true}).and_return('something')
          allow(PuppetLanguageServer::DocumentStore).to receive(:plan_file?).and_return true

          subject.receive_request(request)
        end

        context 'and an error occurs during definition' do
          before(:each) do
            expect(PuppetLanguageServer::Manifest::DefinitionProvider).to receive(:find_definition).and_raise('MockError')
          end

          it 'should log an error message' do
            expect(PuppetLanguageServer).to receive(:log_message).with(:error,/MockError/)

            subject.receive_request(request)
          end

          it 'should reply with nil' do
            expect(request).to receive(:reply_result).with(nil)

            subject.receive_request(request)
          end
        end
      end
    end

    # textDocument/documentSymbol - https://github.com/Microsoft/language-server-protocol/blob/gh-pages/specification.md#document-symbols-request-leftwards_arrow_with_hook
    context 'given a textDocument/documentSymbol request' do
      let(:request_rpc_method) { 'textDocument/documentSymbol' }
      let(:request_params) {{
        'textDocument' => {
          'uri' => file_uri
        }
      }}

      context 'for a file the server does not understand' do
        let(:file_uri) { UNKNOWN_FILENAME }

        it 'should log an error message' do
          expect(PuppetLanguageServer).to receive(:log_message).with(:error,/Unable to provide definition/)

          subject.receive_request(request)
        end

        it 'should reply with nil' do
          expect(request).to receive(:reply_result).with(nil)

          subject.receive_request(request)
        end
      end

      context 'for a puppet manifest file' do
        let(:file_uri) { MANIFEST_FILENAME }

        it 'should call extract_document_symbols method on the Document Symbol Provider' do
          expect(PuppetLanguageServer::Manifest::DocumentSymbolProvider).to receive(:extract_document_symbols)
            .with(Object,{:tasks_mode=>false}).and_return('something')

          subject.receive_request(request)
        end

        it 'should set tasks_mode option if the file is Puppet plan file' do
          expect(PuppetLanguageServer::Manifest::DocumentSymbolProvider).to receive(:extract_document_symbols)
            .with(Object,{:tasks_mode=>true}).and_return('something')
          allow(PuppetLanguageServer::DocumentStore).to receive(:plan_file?).and_return true

          subject.receive_request(request)
        end

        context 'and an error occurs during extraction' do
          before(:each) do
            expect(PuppetLanguageServer::Manifest::DocumentSymbolProvider).to receive(:extract_document_symbols).and_raise('MockError')
          end

          it 'should log an error message' do
            expect(PuppetLanguageServer).to receive(:log_message).with(:error,/MockError/)

            subject.receive_request(request)
          end

          it 'should reply with nil' do
            expect(request).to receive(:reply_result).with(nil)

            subject.receive_request(request)
          end
        end
      end
    end

    context 'given an unknown request' do
      let(:request_rpc_method) { 'unknown_request_method' }

      it 'should log an error message' do
        expect(PuppetLanguageServer).to receive(:log_message).with(:error,"Unknown RPC method #{request_rpc_method}")

        subject.receive_request(request)
      end
    end
  end

  describe '#receive_notification' do
    let(:notification_method) { nil }
    let(:notification_params) { {} }

    context 'given a notification that raises an error' do
      let(:notification_method) { 'exit' }
      before(:each) do
        expect(subject.json_rpc_handler).to receive(:close_connection).and_raise('MockError')
        allow(PuppetLanguageServer::CrashDump).to receive(:write_crash_file)
      end

      it 'should raise an error' do
        expect{ subject.receive_notification(notification_method, notification_params) }.to raise_error(/MockError/)
      end

      it 'should call PuppetLanguageServer::CrashDump.write_crash_file' do
        expect(PuppetLanguageServer::CrashDump).to receive(:write_crash_file)
        expect{ subject.receive_notification(notification_method, notification_params) }.to raise_error(/MockError/)
      end
    end

    context 'given a notification that is protocol implementation dependant' do
      let(:notification_method) { '$/MockNotification' }

      it 'should log a debug message' do
        expect(PuppetLanguageServer).to receive(:log_message).with(:debug, /Ignoring .+ #{Regexp.escape(notification_method)}/)
        subject.receive_notification(notification_method, notification_params)
      end
    end

    # initialized - https://github.com/Microsoft/language-server-protocol/blob/master/protocol.md#initialized
    context 'given an initialized notification' do
      let(:notification_method) { 'initialized' }

      it 'should log a message' do
        expect(PuppetLanguageServer).to receive(:log_message).with(:info,String)

        subject.receive_notification(notification_method, notification_params)
      end
    end

    # exit - https://github.com/Microsoft/language-server-protocol/blob/master/protocol.md#exit-notification
    context 'given an exit notification' do
      let(:notification_method) { 'exit' }

      before(:each) do
        allow(subject).to receive(:close_connection)
      end

      it 'should log a message' do
        expect(PuppetLanguageServer).to receive(:log_message).with(:info,String)

        subject.receive_notification(notification_method, notification_params)
      end

      it 'should close the connection' do
        expect(subject.json_rpc_handler).to receive(:close_connection)

        subject.receive_notification(notification_method, notification_params)
      end
    end

    # textDocument/didOpen - https://github.com/Microsoft/language-server-protocol/blob/master/protocol.md#textDocument_didOpen
    context 'given a textDocument/didOpen notification' do
      shared_examples_for "an opened document with enqueued validation" do |file_uri, file_content|
        let(:notification_method) { 'textDocument/didOpen' }
        let(:notification_params) { {
          'textDocument' => {
            'uri' => file_uri,
            'languageId' => 'puppet',
            'version' => 1,
            'text' => file_content,
          }
        }}

        it 'should add the document to the document store' do
          subject.receive_notification(notification_method, notification_params)
          expect(subject.documents.document(file_uri)).to eq(file_content)
        end

        it 'should enqueue the file for validation' do
          expect(PuppetLanguageServer::ValidationQueue).to receive(:enqueue).with(file_uri, 1, Object)
          subject.receive_notification(notification_method, notification_params)
        end
      end

      before(:each) do
        subject.documents.clear
      end

      context 'for a puppet manifest file' do
        it_should_behave_like "an opened document with enqueued validation", MANIFEST_FILENAME, ERROR_CAUSING_FILE_CONTENT
      end

      context 'for a Puppetfile file' do
        it_should_behave_like "an opened document with enqueued validation", PUPPETFILE_FILENAME, ERROR_CAUSING_FILE_CONTENT
      end

      context 'for an EPP template file' do
        it_should_behave_like "an opened document with enqueued validation", EPP_FILENAME, ERROR_CAUSING_FILE_CONTENT
      end

      context 'for an unknown file' do
        it_should_behave_like "an opened document with enqueued validation", UNKNOWN_FILENAME, ERROR_CAUSING_FILE_CONTENT
      end
    end

    # textDocument/didClose - https://github.com/Microsoft/language-server-protocol/blob/master/protocol.md#didclosetextdocument-notification
    context 'given a textDocument/didClose notification' do
      let(:notification_method) { 'textDocument/didClose' }
      let(:notification_params) { {
        'textDocument' => { 'uri' => file_uri}
      }}
      let(:file_uri) { MANIFEST_FILENAME }
      let(:file_content) { 'file_content' }

      before(:each) do
        subject.documents.clear
        subject.documents.set_document(file_uri,file_content, 0)
      end

      it 'should remove the document from the document store' do
        subject.receive_notification(notification_method, notification_params)
        expect(subject.documents.document(file_uri)).to be_nil
      end
    end

    # textDocument/didChange - https://github.com/Microsoft/language-server-protocol/blob/master/protocol.md#didchangetextdocument-notification
    context 'given a textDocument/didChange notification and a TextDocumentSyncKind of Full' do
      shared_examples_for "a changed document with enqueued validation" do |file_uri, new_file_content|
        let(:notification_params) { {
          'textDocument' => {
            'uri' => file_uri,
            'version' => 2,
          },
          'contentChanges' => [
            {
              'range' => nil,
              'rangeLength' => nil,
              'text' => new_file_content,
            }
          ]
        }}
        let(:notification_method) { 'textDocument/didChange' }
        let(:new_file_content ) { 'new_file_content' }

        it 'should update the document in the document store' do
          subject.receive_notification(notification_method, notification_params)
          expect(subject.documents.document(file_uri)).to eq(new_file_content)
        end

        it 'should enqueue the file for validation' do
          expect(PuppetLanguageServer::ValidationQueue).to receive(:enqueue).with(file_uri, 2, Object)
          subject.receive_notification(notification_method, notification_params)
        end
      end

      before(:each) do
        subject.documents.clear
      end

      context 'for a puppet manifest file' do
        it_should_behave_like "a changed document with enqueued validation", MANIFEST_FILENAME, ERROR_CAUSING_FILE_CONTENT
      end

      context 'for a Puppetfile file' do
        it_should_behave_like "a changed document with enqueued validation", PUPPETFILE_FILENAME, ERROR_CAUSING_FILE_CONTENT
      end

      context 'for an EPP template file' do
        it_should_behave_like "a changed document with enqueued validation", EPP_FILENAME, ERROR_CAUSING_FILE_CONTENT
      end

      context 'for a file the server does not understand' do
        it_should_behave_like "a changed document with enqueued validation", UNKNOWN_FILENAME, ERROR_CAUSING_FILE_CONTENT
      end
    end

    # textDocument/didSave - https://github.com/Microsoft/language-server-protocol/blob/master/protocol.md#didsavetextdocument-notification
    context 'given a textDocument/didSave notification' do
      let(:notification_method) { 'textDocument/didSave' }
      it 'should log a message' do
        expect(PuppetLanguageServer).to receive(:log_message).with(:info,String)

        subject.receive_notification(notification_method, notification_params)
      end
    end

    context 'given an unknown notification' do
      let(:notification_method) { 'unknown_notification_method' }

      it 'should log an error message' do
        expect(PuppetLanguageServer).to receive(:log_message).with(:error,"Unknown RPC notification #{notification_method}")

        subject.receive_notification(notification_method, notification_params)
      end
    end
  end
end
