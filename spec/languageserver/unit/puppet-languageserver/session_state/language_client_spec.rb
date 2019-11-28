require 'spec_helper'
require 'puppet_editor_services/protocol/json_rpc'
require 'puppet_editor_services/protocol/json_rpc_messages'

def pretty_value(value)
  value.nil? ? 'nil' : value.to_s
end

# Requires
#   :settings      : A hashtable of the inbound settings
#   :setting_value : The value that will be set to
RSpec.shared_examples "a client setting" do |method_name|
  [
    { :from => false, :setting => nil,   :expected_setting => false },
    { :from => false, :setting => false, :expected_setting => false },
    { :from => false, :setting => true,  :expected_setting => true },
    { :from => true,  :setting => nil,   :expected_setting => true },
    { :from => true,  :setting => false, :expected_setting => false },
    { :from => true,  :setting => true,  :expected_setting => true },
  ].each do |testcase|
    context "When it transitions from #{pretty_value(testcase[:from])} with a setting value of #{pretty_value(testcase[:setting])}" do
      let(:setting_value) { testcase[:setting] }

      before(:each) do
        subject.instance_variable_set("@#{method_name}".intern, testcase[:from])
      end

      it "should have a cached value to #{testcase[:expected_setting]}" do
        expect(subject.send(method_name)).to eq(testcase[:from])

        subject.parse_lsp_configuration_settings!(settings)
        expect(subject.send(method_name)).to eq(testcase[:expected_setting])
      end
    end
  end
end

# Requires
#   :settings      : A hashtable of the inbound settings
#   :setting_value : The value that will be set to
RSpec.shared_examples "a setting with dynamic registrations" do |method_name, dynamic_reg, registration_method|
  [
    { :from => false, :setting => nil,   :noop       => true },
    { :from => false, :setting => false, :noop       => true },
    { :from => false, :setting => true,  :register   => true },
    { :from => true,  :setting => nil,   :noop       => true },
    { :from => true,  :setting => false, :unregister => true },
    { :from => true,  :setting => true,  :noop       => true },
  ].each do |testcase|
    context "When it transitions from #{pretty_value(testcase[:from])} with a setting value of #{pretty_value(testcase[:setting])}" do
      let(:setting_value) { testcase[:setting] }

      before(:each) do
        subject.instance_variable_set("@#{method_name}".intern, testcase[:from])
      end

      it 'should not call any capabilities', :if => testcase[:noop] do
        expect(subject).to receive(:client_capability).exactly(0).times
        expect(subject).to receive(:register_capability).exactly(0).times
        expect(subject).to receive(:unregister_capability).exactly(0).times

        subject.parse_lsp_configuration_settings!(settings)
      end

      context "when dynamic registration is not supported", :unless => testcase[:noop] do
        before(:each) do
          expect(subject).to receive(:client_capability).with(*dynamic_reg).and_return(false)
        end

        it 'should not call any registration or unregistrations' do
          expect(subject).to receive(:register_capability).exactly(0).times
          expect(subject).to receive(:unregister_capability).exactly(0).times

          subject.parse_lsp_configuration_settings!(settings)
        end
      end

      context "when dynamic registration is supported", :unless => testcase[:noop] do
        before(:each) do
          expect(subject).to receive(:client_capability).with(*dynamic_reg).and_return(true)
        end

        it "should register #{registration_method}", :if => testcase[:register] do
          expect(subject).to receive(:register_capability).with(registration_method, Object)
          expect(subject).to receive(:unregister_capability).exactly(0).times

          subject.parse_lsp_configuration_settings!(settings)
        end

        it "should unregister #{registration_method}", :if => testcase[:unregister] do
          expect(subject).to receive(:unregister_capability).with(registration_method)
          expect(subject).to receive(:register_capability).exactly(0).times

          subject.parse_lsp_configuration_settings!(settings)
        end
      end
    end
  end
end

describe 'PuppetLanguageServer::LanguageClient' do
  let(:server) do
    MockServer.new({}, {}, { :class => PuppetEditorServices::Protocol::JsonRPC }, {})
  end
  let(:subject) { PuppetLanguageServer::LanguageClient.new(server.handler_object) }
  let(:protocol) { server.protocol_object }
  let(:mock_connection) { server.connection_object }

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

  before(:each) do
    allow(PuppetLanguageServer).to receive(:log_message)
  end

  describe '#format_on_type' do
    it 'should be false by default' do
      expect(subject.format_on_type).to eq(false)
    end
  end

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
      expect(protocol).to receive(:send_client_request).with('workspace/configuration', Object)
      expect(subject.send_configuration_request).to eq(true)
    end

    it 'should include the puppet settings' do
      subject.send_configuration_request
      expect(mock_connection.buffer).to include('{"section":"puppet"}')
    end
  end

  # This is tested as part of '#client_capability'
  # describe '#parse_lsp_initialize!' do
  # end

  describe '#parse_lsp_configuration_settings!' do
    describe 'puppet.editorService.formatOnType.enable' do
      let(:settings) do
        { 'puppet' => {
            'editorService' => {
              'formatOnType' => {
                'enable' => setting_value
              }
            }
          }
        }
      end

      it_behaves_like 'a client setting', :format_on_type

      it_behaves_like 'a setting with dynamic registrations',
        :format_on_type,
        ['textDocument', 'onTypeFormatting', 'dynamicRegistration'],
        'textDocument/onTypeFormatting'
    end
  end

  describe '#capability_registrations' do
    let(:method_name) { 'mockMethod' }
    let(:method_options) { {} }
    let(:request_id) { 'id001' }

    it 'defaults to false' do
      expect(subject.capability_registrations(method_name)).to eq([{:registered => false, :state => :complete}])
    end

    it 'should track the registration process as it completes succesfully' do
      req_method_name = nil
      req_method_params = nil
      # Remember the registration so we can fake a response later
      allow(protocol).to receive(:send_client_request) do |n, p|
        req_method_name = n
        req_method_params = p
      end
      # Fake the request id
      allow(subject).to receive(:new_request_id).and_return(request_id)

      # Should start out not registered
      expect(subject.capability_registrations(method_name)).to eq([{:registered => false, :state => :complete}])
      # Send as registration request
      subject.register_capability(method_name, method_options)
      # Should show as in progress
      expect(subject.capability_registrations(method_name)).to eq([{:registered => false, :state => :pending, :id => request_id}])
      # Mock a valid response
      response = ::PuppetEditorServices::Protocol::JsonRPCMessages::ResponseMessage.new.from_h!('id' => 0, 'result' => nil)
      original_request = ::PuppetEditorServices::Protocol::JsonRPCMessages::RequestMessage.new.from_h!('id' => 0, 'method' => req_method_name, 'params' => req_method_params)
      subject.parse_register_capability_response!(response, original_request)
      # Should show registered
      expect(subject.capability_registrations(method_name)).to eq([{:registered => true, :state => :complete, :id => request_id}])
    end

    it 'should track the registration process as it fails' do
      req_method_name = nil
      req_method_params = nil
      # Remember the registration so we can fake a response later
      allow(protocol).to receive(:send_client_request) do |n, p|
        req_method_name = n
        req_method_params = p
      end
      # Fake the request id
      allow(subject).to receive(:new_request_id).and_return(request_id)

      # Should start out not registered
      expect(subject.capability_registrations(method_name)).to eq([{:registered => false, :state => :complete}])
      # Send as registration request
      subject.register_capability(method_name, method_options)
      # Should show as in progress
      expect(subject.capability_registrations(method_name)).to eq([{:registered => false, :state => :pending, :id => request_id}])
      # Mock an error response
      response = ::PuppetEditorServices::Protocol::JsonRPCMessages::ResponseMessage.new.from_h!('id' => 0, 'error' => { 'code' => -1, 'message' => 'mock message' })
      original_request = ::PuppetEditorServices::Protocol::JsonRPCMessages::RequestMessage.new.from_h!('id' => 0, 'method' => req_method_name, 'params' => req_method_params)
      subject.parse_register_capability_response!(response, original_request)
      # Should show registered
      expect(subject.capability_registrations(method_name)).to eq([{:registered => false, :state => :complete, :id => request_id}])
    end

    it 'should preserve the registration state until it is completed' do
      req_method_name = nil
      req_method_params = nil
      # Remember the registration so we can fake a response later
      allow(protocol).to receive(:send_client_request) do |n, p|
        req_method_name = n
        req_method_params = p
      end
      # Fake the request id
      request_id2 = 'id002'
      allow(subject).to receive(:new_request_id).and_return(request_id, request_id2)

      # Should start out not registered
      expect(subject.capability_registrations(method_name)).to eq([{:registered => false, :state => :complete}])
      # Send as registration request
      subject.register_capability(method_name, method_options)
      # Mock a valid response
      response = ::PuppetEditorServices::Protocol::JsonRPCMessages::ResponseMessage.new.from_h!('id' => 0, 'result' => nil)
      original_request = ::PuppetEditorServices::Protocol::JsonRPCMessages::RequestMessage.new.from_h!('id' => 0, 'method' => req_method_name, 'params' => req_method_params)
      subject.parse_register_capability_response!(response, original_request)
      # Should show registered
      expect(subject.capability_registrations(method_name)).to eq([{:registered => true, :state => :complete, :id => request_id}])
      # Send another registration request
      subject.register_capability(method_name, method_options)
      # Should show as in progress
      expect(subject.capability_registrations(method_name)).to eq([
        {:registered => true,  :state => :complete, :id => request_id},
        {:registered => false, :state => :pending,  :id => request_id2}
      ])
      # Mock an error response
      response = ::PuppetEditorServices::Protocol::JsonRPCMessages::ResponseMessage.new.from_h!('id' => 0, 'error' => { 'code' => -1, 'message' => 'mock message' })
      original_request = ::PuppetEditorServices::Protocol::JsonRPCMessages::RequestMessage.new.from_h!('id' => 0, 'method' => req_method_name, 'params' => req_method_params)
      subject.parse_register_capability_response!(response, original_request)
      # Should still show registered
      expect(subject.capability_registrations(method_name)).to eq([
        {:registered => true,  :state => :complete, :id => request_id},
        {:registered => false, :state => :complete,  :id => request_id2}
      ])
    end
  end

  describe '#register_capability' do
    let(:method_name) { 'mockMethod' }
    let(:method_options) { {} }

    it 'should send a client request and return true' do
      expect(protocol).to receive(:send_client_request).with('client/registerCapability', Object)
      expect(subject.register_capability(method_name, method_options)).to eq(true)
    end

    it 'should include the method to register' do
      subject.register_capability(method_name, method_options)
      expect(mock_connection.buffer).to include("\"method\":\"#{method_name}\"")
    end

    it 'should include the parameters to register' do
      subject.register_capability(method_name, method_options)
      expect(mock_connection.buffer).to include('"registerOptions":{}')
    end

    it 'should log a message if a registration is already in progress' do
      allow(protocol).to receive(:send_client_request)
      expect(PuppetLanguageServer).to receive(:log_message).with(:warn, /#{method_name}/)

      subject.register_capability(method_name, method_options)
      subject.register_capability(method_name, method_options)
    end

    it 'should not log a message if a previous registration completed' do
      method_name = nil
      method_params = nil
      # Remember the registration so we can fake a response later
      allow(protocol).to receive(:send_client_request) do |n, p|
        method_name = n
        method_params = p
      end
      expect(PuppetLanguageServer).to_not receive(:log_message).with(:warn, /#{method_name}/)
      # Send as registration request
      subject.register_capability(method_name, method_options)
      # Mock a valid response
      response = ::PuppetEditorServices::Protocol::JsonRPCMessages::ResponseMessage.new.from_h!('id' => 0, 'result' => nil)
      original_request = ::PuppetEditorServices::Protocol::JsonRPCMessages::RequestMessage.new.from_h!('id' => 0, 'method' => method_name, 'params' => method_params)
      subject.parse_register_capability_response!(response, original_request)

      subject.register_capability(method_name, method_options)
    end
  end

  describe '#unregister_capability' do
    let(:method_name) { 'mockMethod' }

    before(:each) do
      # Mock an already succesful registration
      subject.instance_variable_set(:@registrations, {
        method_name => [{ :id => 'id001', :state => :complete, :registered => true }]
      })
    end

    it 'should send a client request and return true' do
      expect(protocol).to receive(:send_client_request).with('client/unregisterCapability', Object)
      expect(subject.unregister_capability(method_name)).to eq(true)
    end

    it 'should include the method to register' do
      subject.unregister_capability(method_name)
      expect(mock_connection.buffer).to include("\"method\":\"#{method_name}\"")
    end

    it 'should log a message if a registration is already in progress' do
      allow(protocol).to receive(:send_client_request)
      expect(PuppetLanguageServer).to receive(:log_message).with(:warn, /#{method_name}/)

      subject.unregister_capability(method_name)
      subject.unregister_capability(method_name)
    end

    it 'should not log a message if a previous registration completed' do
      req_method_name = nil
      req_method_params = nil
      # Remember the registration so we can fake a response later
      allow(protocol).to receive(:send_client_request) do |n, p|
        req_method_name = n
        req_method_params = p
      end

      expect(PuppetLanguageServer).to_not receive(:log_message).with(:warn, /#{method_name}/)
      # Send as registration request
      subject.unregister_capability(method_name)
      # Mock a valid response
      response = ::PuppetEditorServices::Protocol::JsonRPCMessages::ResponseMessage.new.from_h!('id' => 0, 'result' => nil)
      original_request = ::PuppetEditorServices::Protocol::JsonRPCMessages::RequestMessage.new.from_h!('id' => 0, 'method' => req_method_name, 'params' => req_method_params)
      subject.parse_unregister_capability_response!(response, original_request)

      subject.unregister_capability(method_name)
    end

    it 'should not deregister methods that have not been registerd' do
      expect(protocol).to_not receive(:send_client_request)

      subject.unregister_capability('unknown')
    end

    it 'should not deregister methods that are no longer registerd' do
      expect(protocol).to_not receive(:send_client_request)

      subject.instance_variable_set(:@registrations, {
        method_name => [{ :id => 'id001', :state => :complete, :registered => false }]
      })

      subject.unregister_capability(method_name)
    end
  end

  describe '#parse_register_capability_response!' do
    let(:request_id) { 0 }
    let(:response_result) { nil }
    let(:response) { ::PuppetEditorServices::Protocol::JsonRPCMessages::ResponseMessage.new.from_h!('id' => request_id, 'result' => response_result) }
    let(:original_request) { ::PuppetEditorServices::Protocol::JsonRPCMessages::RequestMessage.new.from_h!('id' => request_id, 'method' => request_method, 'params' => request_params) }

    context 'Given an original request that is not a registration' do
      let(:request_method) { 'mockMethod' }
      let(:request_params) { {} }

      it 'should raise an error if the original request was not a registration' do
        expect{ subject.parse_register_capability_response!(response, original_request) }.to raise_error(/client\/registerCapability/)
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
        expect(subject).to receive(:send_configuration_request)
        subject.parse_register_capability_response!(response, original_request)
      end
    end

    context 'Given a valid original request' do
      let(:request_method) { 'client/registerCapability' }
      let(:request_params) do
        params = LSP::RegistrationParams.new.from_h!('registrations' => [])
        params.registrations << LSP::Registration.new.from_h!('id' => 'abc123', 'method' => 'validMethod', 'registerOptions' => {})
        params
      end

      context 'that failed' do
        before(:each) do
          response.error = { 'code' => -1, 'message' => 'mock message' }
          response.is_successful = false
        end

        it 'should not log the registration' do
          expect(PuppetLanguageServer).to_not receive(:log_message).with(:info, /validMethod/)

          subject.parse_register_capability_response!(response, original_request)
        end
      end

      context 'that succeeded' do
        it 'should log the registration' do
          expect(PuppetLanguageServer).to receive(:log_message).with(:info, /validMethod/)

          subject.parse_register_capability_response!(response, original_request)
        end
      end
    end
  end

  describe '#parse_unregister_capability_response!' do
    let(:request_id) { 0 }
    let(:response_result) { nil }
    let(:response) { ::PuppetEditorServices::Protocol::JsonRPCMessages::ResponseMessage.new.from_h!('id' => request_id, 'result' => response_result) }
    let(:original_request) { ::PuppetEditorServices::Protocol::JsonRPCMessages::RequestMessage.new.from_h!('id' => request_id, 'method' => request_method, 'params' => request_params) }
    let(:method_name) { 'validMethod' }
    let(:initial_registration) { true }

    before(:each) do
      # Mock an already succesful registration
      subject.instance_variable_set(:@registrations, {
        method_name => [{ :id => 'id001', :state => :complete, :registered => initial_registration }]
      })
    end

    context 'Given an original request that is not an unregistration' do
      let(:request_method) { 'mockMethod' }
      let(:request_params) { {} }

      it 'should raise an error if the original request was not a registration' do
        expect{ subject.parse_unregister_capability_response!(response, original_request) }.to raise_error(/client\/unregisterCapability/)
      end
    end

    context 'Given a valid original request' do
      let(:request_method) { 'client/unregisterCapability' }
      let(:request_params) do
        params = LSP::UnregistrationParams.new.from_h!('unregisterations' => [])
        params.unregisterations << LSP::Unregistration.new.from_h!('id' => 'id001', 'method' => method_name)
        params
      end

      before(:each) do
        # Mimic an unregistration that is in progress
        subject.instance_variable_set(:@registrations, {
          method_name => [{ :id => 'id001', :state => :pending, :registered => initial_registration }]
        })
      end

      context 'that failed' do
        before(:each) do
          response.error = { 'code' => -1, 'message' => 'mock message' }
          response.is_successful = false
        end

        context 'and was previously registered' do
          it 'should retain that it is registered' do
            subject.parse_unregister_capability_response!(response, original_request)

            expect(subject.capability_registrations(method_name)).to eq([{:id=>"id001", :registered=>true, :state=>:complete}])
          end
        end

        context 'and was not previously registered' do
          let(:initial_registration) { false }

          it 'should no longer be in the registration list' do
            subject.parse_unregister_capability_response!(response, original_request)

            expect(subject.capability_registrations(method_name)).to eq([{ :registered => false, :state => :complete }])
          end
        end
      end

      context 'that succeeded' do
        it 'should log the registration' do
          expect(PuppetLanguageServer).to receive(:log_message).with(:info, /validMethod/)

          subject.parse_unregister_capability_response!(response, original_request)
        end

        it 'should no longer be in the registration list' do
          subject.parse_unregister_capability_response!(response, original_request)

          expect(subject.capability_registrations(method_name)).to eq([{ :registered => false, :state => :complete }])
        end
      end
    end
  end
end
