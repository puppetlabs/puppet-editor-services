require 'spec_helper'
require 'spec_editor_client'
require 'open3'

#                    (X)        = Tested
#                    ( ) or (?) = Not yet tested
#                    (-)        = Will not test / Not applicable
#
#                            |               Test in?              |
#      LSP Feature           | Single File | Module | Control Repo |
# ---------------------------|-------------|--------|--------------|
# Initialization             |      X      |    ?   |       ?      |
# Open a document            |      X      |        |              |
# Diagnostics response       |      X      |        |              |
# Hover (Class)              |      X      |        |              |
# Puppet resource            |      X      |        |              |
# Puppet facts               |      X      |        |              |
# Node graph preview         |      X      |        |              |
# Puppetfile Dependencies    |      -      |    -   |       X      |
# Completion (Typing)        |      X      |    -   |       -      |
# Completion (Invoked)       |      X      |    -   |       -      |
# Completion Resolution      |      X      |    -   |       -      |
# Signature request          |      X      |    -   |       -      |
# Format document            |      X      |    -   |       -      |
# Format range               |      X      |    -   |       -      |
# OnType Formatting          |      X      |    -   |       -      |
# Document Symbols           |      X      |    -   |       -      |
# Workspace Symbols          |      -      |        |              |

describe 'End to End Testing' do
  before(:each) do
    @server_port = 8082 + Random.rand(1024)
    @server_host = 'localhost'
    @server_pid = -1

    # Start the language server
    server_entrypoint = File.join($root_dir,'puppet-languageserver')
    puppet_settings = ['--vardir', File.join($fixtures_dir, 'cache'), '--confdir', File.join($fixtures_dir, 'confdir')].join(',')

    cmd = [
      'ruby',server_entrypoint,
      '--timeout=10',
      "--port=#{@server_port}",
      "--ip=#{@server_host}",
      "--puppet-settings=#{puppet_settings}",
    ]
    cmd << "--debug=#{ENV['SPEC_LOG']}" unless ENV['SPEC_LOG'].nil?

    @server_stdin, @server_stdout, @server_stderr, wait_thr = Open3.popen3(*cmd)

    @server_pid = wait_thr.pid
    # Wait for something to be output from the Language Server.  This indicates it's alive and ready for a connection
    result = IO.select([@server_stdout], [], [], 30)
    raise('Language Server did not start up in the required timespan') unless result

    # Now connect to the Language Server
    @client = EditorClient.new(@server_host, @server_port)
    @client.debug = !ENV['SPEC_DEBUG'].nil?
  end

  after(:each) do
    @client.close unless @client.nil? || @client.closed?
    Process.kill("KILL", @server_pid) rescue true
    @server_stdin.close
    @server_stdout.close
    @server_stderr.close
  end

  def path_to_uri(path)
    PuppetLanguageServer::UriHelper.build_file_uri(path)
  end

  context 'Processing a single file' do
    let(:workspace) { nil }
    let(:manifest_file) { File.join($fixtures_dir, 'end_to_end_manifest.pp') }
    let(:manifest_uri) { path_to_uri(manifest_file) }

    it 'should act like a valid language server' do
      # initialize_request
      @client.send_data(@client.initialize_request(@client.next_seq_id, workspace))
      expect(@client).to receive_message_with_request_id_within_timeout([@client.current_seq_id, 5])
      result = @client.data_from_request_seq_id(@client.current_seq_id)
      # Ensure required capabilites are enabled
      expect(result['result']['capabilities']).to include(
        {
          'textDocumentSync' => 1,
          'hoverProvider' => true,
          'completionProvider' => {
            'resolveProvider' => true,
            'triggerCharacters' => ['>', '$', '[', '=']
          },
          'definitionProvider' => true,
          'documentSymbolProvider' => true,
          'workspaceSymbolProvider' => true,
          'signatureHelpProvider' => {
            'triggerCharacters' => ['(', ',']
          },
          'documentOnTypeFormattingProvider' => {
            'firstTriggerCharacter' => '>' # Dynamic Registration is disabled in acceptance tests
          }
        }
      )

      # initialized event
      @client.send_data(@client.initialized_notification)

      # Send the client settings
      @client.send_client_settings

      # Wait for the language server to finish loading the Puppet information
      @client.clear_messages!
      @client.wait_for_puppet_loading(120)

      # Open a document
      @client.clear_messages!
      @client.send_data(@client.did_open_notification(manifest_file, 1))
      # Wait for a diagnostics response
      expect(@client).to receive_notification_within_timeout(['textDocument/publishDiagnostics', 5])
      result = @client.data_from_notification_name('textDocument/publishDiagnostics')
      expect(result['params']['uri']).to match(/\/end_to_end_manifest.pp$/)
      expect(result['params']['diagnostics']).not_to be_empty

      # Get hover result from a built-in class (user)
      @client.clear_messages!
      @client.send_data(@client.hover_request(@client.next_seq_id, manifest_uri, 4, 5))
      expect(@client).to receive_message_with_request_id_within_timeout([@client.current_seq_id, 5])
      result = @client.data_from_request_seq_id(@client.current_seq_id)
      #   Expect something to be returned
      expect(result['result']['contents']).not_to be_nil
      expect(result['result']['contents']).not_to be_empty

      # Puppet Facts request
      @client.clear_messages!
      @client.send_data(@client.puppet_getfacts_request(@client.next_seq_id))
      expect(@client).to receive_message_with_request_id_within_timeout([@client.current_seq_id, 15])
      result = @client.data_from_request_seq_id(@client.current_seq_id)
      #   Expect there to be some facts
      expect(result['result']['facts']).not_to be_nil
      expect(result['result']['facts']).not_to be_empty
      #   Expect core facts. Ref https://puppet.com/docs/facter/latest/core_facts.html
      %w[facterversion kernel os system_uptime].each do |factname|
        expect(result['result']['facts'][factname]).not_to be_nil
        expect(result['result']['facts'][factname]).not_to be_empty
      end
      #   Expect nested core facts. Ref https://puppet.com/docs/facter/latest/core_facts.html
      expect(result['result']['facts']['os']['release']).not_to be_nil
      expect(result['result']['facts']['os']['release']).not_to be_empty

      # Puppet Resource request
      @client.clear_messages!
      @client.send_data(@client.puppet_getresource_request(@client.next_seq_id, 'user'))
      expect(@client).to receive_message_with_request_id_within_timeout([@client.current_seq_id, 15])
      result = @client.data_from_request_seq_id(@client.current_seq_id)
      #   Expect something to be returned
      expect(result['result']['data']).not_to be_nil
      expect(result['result']['data']).not_to be_empty

      # Node Graph request
      @client.clear_messages!
      @client.send_data(@client.puppet_compilenodegraph_request(@client.next_seq_id, manifest_uri))
      expect(@client).to receive_message_with_request_id_within_timeout([@client.current_seq_id, 5])
      result = @client.data_from_request_seq_id(@client.current_seq_id)
      #   Expect something to be returned
      expect(result['result']['edges']).to be_empty
      expect(result['result']['vertices']).to include( { 'label' => 'User[bar]' } )

      # Completion request (manual trigger) inside a class
      @client.clear_messages!
      @client.send_data(@client.completion_request(@client.next_seq_id, manifest_uri, 9, 0))
      expect(@client).to receive_message_with_request_id_within_timeout([@client.current_seq_id, 5])
      result = @client.data_from_request_seq_id(@client.current_seq_id)
      #   Expect something to be returned
      expect(result['result']['items'].count).to be > 5
      #   Find the first resource completion item so we can resolve it next
      completion_item = result['result']['items'].find { |item| item['data']['type'] == 'resource_type' }

      # Completion Item Resolve request
      @client.clear_messages!
      @client.send_data(@client.completion_resolve_request(@client.next_seq_id, completion_item))
      expect(@client).to receive_message_with_request_id_within_timeout([@client.current_seq_id, 5])
      result = @client.data_from_request_seq_id(@client.current_seq_id)
      #   Expect the item to be resolved
      expect(completion_item['documentation']).to be_nil
      expect(result['result']['documentation']).not_to be_nil

      # Autocomplete while typing
      @client.clear_messages!
      #   Update the document
      original_content = @client.document_content(manifest_file)
      @client.send_data(@client.did_change_notification(manifest_file, original_content + "\n\n$foo = $facts[]\n"))
      #   Send a completion request for inside the brackets
      @client.send_data(@client.completion_request(@client.next_seq_id, manifest_uri, 16, 14, LSP::CompletionTriggerKind::TRIGGERCHARACTER, '['))
      expect(@client).to receive_message_with_request_id_within_timeout([@client.current_seq_id, 5])
      result = @client.data_from_request_seq_id(@client.current_seq_id)
      #   Expect something about facts to be returned
      expect(result['result']['items']).not_to be_nil
      fact_item = result['result']['items'].find { |item| item['data']['type'] == 'variable_expr_fact' }
      expect(fact_item).not_to be_nil
      #   Revert the document change
      @client.send_data(@client.did_change_notification(manifest_file, original_content))
      #   Wait for a diagnostics response
      expect(@client).to receive_notification_within_timeout(['textDocument/publishDiagnostics', 5])

      # Get signature request for a built-in function (split)
      @client.clear_messages!
      @client.send_data(@client.signture_help_request(@client.next_seq_id, manifest_uri, 10, 25))
      expect(@client).to receive_message_with_request_id_within_timeout([@client.current_seq_id, 5])
      result = @client.data_from_request_seq_id(@client.current_seq_id)
      #   Expect something to be returned
      expect(result['result']['signatures']).not_to be_nil
      expect(result['result']['signatures']).not_to be_empty

      # Document Formatting
      @client.clear_messages!
      @client.send_data(@client.formatting_request(@client.next_seq_id, manifest_uri))
      expect(@client).to receive_message_with_request_id_within_timeout([@client.current_seq_id, 5])
      result = @client.data_from_request_seq_id(@client.current_seq_id)
      # Expect an error as we don't support it
      expect(result['error']['code']).to eq(PuppetEditorServices::Protocol::JsonRPC::CODE_METHOD_NOT_FOUND)

      # Range Formatting
      @client.clear_messages!
      @client.send_data(@client.range_formatting_request(@client.next_seq_id, manifest_uri, 4, 0, 8, 3))
      expect(@client).to receive_message_with_request_id_within_timeout([@client.current_seq_id, 5])
      result = @client.data_from_request_seq_id(@client.current_seq_id)
      # Expect an error as we don't support it
      expect(result['error']['code']).to eq(PuppetEditorServices::Protocol::JsonRPC::CODE_METHOD_NOT_FOUND)

      # OnType Formatting
      #   Enable ontype formatting
      @client.client_settings['puppet']['editorService']['formatOnType']['enable'] = true
      @client.send_client_settings
      #   Wait for the settings to take effect
      sleep(1)
      @client.clear_messages!
      @client.send_data(@client.ontype_format_request(@client.next_seq_id, manifest_uri, 6, 22, '>'))
      expect(@client).to receive_message_with_request_id_within_timeout([@client.current_seq_id, 5])
      result = @client.data_from_request_seq_id(@client.current_seq_id)
      #   Expect something to be returned
      expect(result['result']).not_to be_nil
      #   Disable ontype formatting
      @client.client_settings['puppet']['editorService']['formatOnType']['enable'] = false
      @client.send_client_settings
      #   Wait for the settings to take effect
      sleep(1)

      # Document symbols
      @client.clear_messages!
      @client.send_data(@client.document_symbols_request(@client.next_seq_id, manifest_uri))
      expect(@client).to receive_message_with_request_id_within_timeout([@client.current_seq_id, 5])
      result = @client.data_from_request_seq_id(@client.current_seq_id)
      #   Expect something to be returned
      expect(result['result'].count).to be > 0

      # Start shutdown process
      @client.clear_messages!
      @client.send_data(@client.shutdown_request(@client.next_seq_id))
      expect(@client).to receive_message_with_request_id_within_timeout([@client.current_seq_id, 5])
      result = @client.data_from_request_seq_id(@client.current_seq_id)
      #   Expect something to be returned
      expect(result['result']).to be_nil

      # Exit process
      @client.clear_messages!
      @client.send_data(@client.exit_notification)
      expect(@client).to close_within_timeout(5)
    end
  end

  context 'Processing a Puppet module' do
  end

  context 'Processing a Control Repo' do
    let(:workspace) { File.join($fixtures_dir, 'control_repos', 'valid') }
    let(:puppetfile) { File.join(workspace, 'Puppetfile') }
    let(:puppetfile_uri) { path_to_uri(puppetfile) }

    it 'should act like a valid language server' do
      # initialize_request
      @client.send_data(@client.initialize_request(@client.next_seq_id, workspace))
      expect(@client).to receive_message_with_request_id_within_timeout([@client.current_seq_id, 5])
      result = @client.data_from_request_seq_id(@client.current_seq_id)
      # Ensure required capabilites are enabled
      expect(result['result']['capabilities']).to include(
        {
          'textDocumentSync' => 1,
          'hoverProvider' => true,
          'completionProvider' => {
            'resolveProvider' => true,
            'triggerCharacters' => ['>', '$', '[', '=']
          },
          'definitionProvider' => true,
          'documentSymbolProvider' => true,
          'workspaceSymbolProvider' => true,
          'signatureHelpProvider' => {
            'triggerCharacters' => ['(', ',']
          },
          'documentOnTypeFormattingProvider' => {
            'firstTriggerCharacter' => '>' # Dynamic Registration is disabled in acceptance tests
          }
        }
      )

      # initialized event
      @client.send_data(@client.initialized_notification)

      # Send the client settings
      @client.send_client_settings

      # Wait for the language server to finish loading the Puppet information
      @client.clear_messages!
      @client.wait_for_puppet_loading(120)

      # Open the Puppetfile
      @client.clear_messages!
      @client.send_data(@client.did_open_notification(puppetfile, 1))
      # Wait a moment for it to load.
      sleep(1)

      # Puppetfile Dependencies
      @client.send_data(@client.puppetfile_getdependencies_request(@client.next_seq_id, puppetfile_uri))
      expect(@client).to receive_message_with_request_id_within_timeout([@client.current_seq_id, 10])
      result = @client.data_from_request_seq_id(@client.current_seq_id)
       #   Expect something to be returned
       expect(result['result']).not_to be_nil
       expect(result['result']['dependencies']).not_to be_nil
       expect(result['result']['dependencies']).not_to be_empty

      # Start shutdown process
      @client.clear_messages!
      @client.send_data(@client.shutdown_request(@client.next_seq_id))
      expect(@client).to receive_message_with_request_id_within_timeout([@client.current_seq_id, 5])
      result = @client.data_from_request_seq_id(@client.current_seq_id)
      #   Expect something to be returned
      expect(result['result']).to be_nil

      # Exit process
      @client.clear_messages!
      @client.send_data(@client.exit_notification)
      expect(@client).to close_within_timeout(5)
    end
  end
end
