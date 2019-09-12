require 'spec_helper'

describe 'PuppetLanguageServer::LanguageClient' do
  let(:subject_options) {}
  let(:subject) { PuppetLanguageServer::LanguageClient.new }
  let(:initialize_params) do
    # Example capabilities from VS Code
    {
      "procesId" => 0,
      "rootUri" => 'file://something/somewhere',
      "capabilities" => {
        "workspace" => {
          "applyEdit" => true,
          "workspaceEdit" => {
            "documentChanges" => true,
            "resourceOperations" => ["create", "rename", "delete"],
            "failureHandling" => "textOnlyTransactional"
          },
          "didChangeConfiguration" => {
            "dynamicRegistration" => true
          },
          "didChangeWatchedFiles" => {
            "dynamicRegistration" => true
          },
          "symbol" => {
            "dynamicRegistration" => true,
            "symbolKind" => {
              "valueSet" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26]
            }
          },
          "executeCommand" => {
            "dynamicRegistration" => true
          },
          "configuration" => true,
          "workspaceFolders" => true
        },
        "textDocument" => {
          "publishDiagnostics" => {
            "relatedInformation" => true
          },
          "synchronization" => {
            "dynamicRegistration" => true,
            "willSave" => true,
            "willSaveWaitUntil" => true,
            "didSave" => true
          },
          "completion" => {
            "dynamicRegistration" => true,
            "contextSupport" => true,
            "completionItem" => {
              "snippetSupport" => true,
              "commitCharactersSupport" => true,
              "documentationFormat" => ["markdown", "plaintext"],
              "deprecatedSupport" => true,
              "preselectSupport" => true
            },
            "completionItemKind" => {
              "valueSet" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25]
            }
          },
          "hover" => {
            "dynamicRegistration" => true,
            "contentFormat" => ["markdown", "plaintext"]
          },
          "signatureHelp" => {
            "dynamicRegistration" => true,
            "signatureInformation" => {
              "documentationFormat" => ["markdown", "plaintext"],
              "parameterInformation" => {
                "labelOffsetSupport" => true
              }
            }
          },
          "definition" => {
            "dynamicRegistration" => true,
            "linkSupport" => true
          },
          "references" => {
            "dynamicRegistration" => true
          },
          "documentHighlight" => {
            "dynamicRegistration" => true
          },
          "documentSymbol" => {
            "dynamicRegistration" => true,
            "symbolKind" => {
              "valueSet" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26]
            },
            "hierarchicalDocumentSymbolSupport" => true
          },
          "codeAction" => {
            "dynamicRegistration" => true,
            "codeActionLiteralSupport" => {
              "codeActionKind" => {
                "valueSet" => ["", "quickfix", "refactor", "refactor.extract", "refactor.inline", "refactor.rewrite", "source", "source.organizeImports"]
              }
            }
          },
          "codeLens" => {
            "dynamicRegistration" => true
          },
          "formatting" => {
            "dynamicRegistration" => true
          },
          "rangeFormatting" => {
            "dynamicRegistration" => true
          },
          "onTypeFormatting" => {
            "dynamicRegistration" => true
          },
          "rename" => {
            "dynamicRegistration" => true,
            "prepareSupport" => true
          },
          "documentLink" => {
            "dynamicRegistration" => true
          },
          "typeDefinition" => {
            "dynamicRegistration" => true,
            "linkSupport" => true
          },
          "implementation" => {
            "dynamicRegistration" => true,
            "linkSupport" => true
          },
          "colorProvider" => {
            "dynamicRegistration" => true
          },
          "foldingRange" => {
            "dynamicRegistration" => true,
            "rangeLimit" => 5000,
            "lineFoldingOnly" => true
          },
          "declaration" => {
            "dynamicRegistration" => true,
            "linkSupport" => true
          }
        }
      }
    }
  end
  let(:json_rpc_handler) { MockJSONRPCHandler.new }
  let(:message_router) { MockMessageRouter.new.tap { |i| i.json_rpc_handler = json_rpc_handler } }

  describe '#client_capability' do
    before(:each) do
      subject.parse_lsp_initialize!(initialize_params)
    end

    it 'should return nil for settings that do not exist' do
      expect(subject.client_capability('does_not_exist')).to be nil
      expect(subject.client_capability('workspace', 'does_not_exist')).to be nil
      expect(subject.client_capability('workspace', 'does_not_exist', 'unknown')).to be nil
    end

    it 'should return settings that do exist' do
      expect(subject.client_capability('workspace', 'didChangeConfiguration', 'dynamicRegistration')).to eq(true)
      expect(subject.client_capability('textDocument', 'foldingRange', 'rangeLimit')).to eq(5000)
      expect(subject.client_capability('textDocument', 'rangeFormatting')).to eq({"dynamicRegistration" => true})
    end
  end

  describe '#send_configuration_request' do
    it 'should send a client request and return true' do
      expect(json_rpc_handler).to receive(:send_client_request).with('workspace/configuration', Object)
      expect(subject.send_configuration_request(message_router)).to eq(true)
    end

    it 'should include the puppet settings' do
      subject.send_configuration_request(message_router)
      expect(json_rpc_handler.connection.buffer).to include('{"section":"puppet"}')
    end
  end

  # This is tested as part of '#client_capability'
  # describe '#parse_lsp_initialize!' do
  # end

  describe '#parse_lsp_configuration_settings!' do
    # TODO: Future use.
  end

  describe '#register_capability' do
    let(:method_name) { 'mockMethod' }
    let(:method_options) { {} }

    it 'should send a client request and return true' do
      expect(json_rpc_handler).to receive(:send_client_request).with('client/registerCapability', Object)
      expect(subject.register_capability(message_router, method_name, method_options)).to eq(true)
    end

    it 'should include the method to register' do
      subject.register_capability(message_router, method_name, method_options)
      expect(json_rpc_handler.connection.buffer).to include("\"method\":\"#{method_name}\"")
    end

    it 'should include the parameters to register' do
      subject.register_capability(message_router, method_name, method_options)
      expect(json_rpc_handler.connection.buffer).to include('"registerOptions":{}')
    end
  end

  describe '#parse_register_capability_response!' do
    let(:request_id) { 0 }
    let(:response_result) { nil }
    let(:response) { {'jsonrpc'=>'2.0', 'id'=> request_id, 'result' => response_result } }
    let(:original_request) { {'jsonrpc'=>'2.0', 'id'=> request_id, 'method' => request_method, 'params' => request_params} }

    context 'Given an original request that is not a registration' do
      let(:request_method) { 'mockMethod' }
      let(:request_params) { {} }

      it 'should raise an error if the original request was not a registration' do
        expect{ subject.parse_register_capability_response!(message_router, response, original_request) }.to raise_error(/client\/registerCapability/)
      end
    end

    context 'Given an original request of workspace/didChangeConfiguration' do
      let(:request_method) { 'client/registerCapability' }
      let(:request_params) do
        params = LSP::RegistrationParams.new.from_h!('registrations' => [])
        params.registrations << LSP::Registration.new.from_h!('id' => 'abc123', 'method' => 'workspace/didChangeConfiguration', 'registerOptions' => {})
        params
      end

      it 'should send a configuration request' do
        expect(subject).to receive(:send_configuration_request).with(message_router)
        subject.parse_register_capability_response!(message_router, response, original_request)
      end
    end

    context 'Given a valid original request' do
      let(:request_method) { 'client/registerCapability' }
      let(:request_params) do
        params = LSP::RegistrationParams.new.from_h!('registrations' => [])
        params.registrations << LSP::Registration.new.from_h!('id' => 'abc123', 'method' => 'validMethod', 'registerOptions' => {})
        params
      end

      it 'should log the registration' do
        allow(PuppetLanguageServer).to receive(:log_message)
        expect(PuppetLanguageServer).to receive(:log_message).with(:info, /validMethod/)

        subject.parse_register_capability_response!(message_router, response, original_request)
      end
    end
  end
end
