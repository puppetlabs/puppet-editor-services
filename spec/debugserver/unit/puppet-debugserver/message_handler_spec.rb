require 'spec_debug_helper'
require 'spec_debug_client'
require 'json'

describe 'PuppetDebugServer::MessageHandler' do
  let(:server) do
    MockServer.new(
      {},
      { class: MockConnection },
      { class: MockProtocol },
      { class: PuppetDebugServer::MessageHandler }
    )
  end
  let(:subject)    { server.handler_object }
  let(:protocol)   { server.protocol_object }
  let(:connection) { server.connection_object }
  let(:client)     { DebugClient.new }

  let(:debug_session) { PuppetDebugServer::PuppetDebugSession.new }

  before(:each) do
    allow(PuppetDebugServer).to receive(:log_message)
    allow(PuppetEditorServices).to receive(:log_message)
    allow(PuppetDebugServer::PuppetDebugSession).to receive(:instance).and_return(debug_session)
  end

  def response_for(seq_id)
    connection.sent_objects.find { |o| o['request_seq'] == seq_id }
  end

  def event_named(name)
    connection.sent_objects.find { |o| o['type'] == 'event' && o['event'] == name }
  end

  # --- Event helpers ---

  describe '#send_exited_event' do
    it 'sends an exited event via protocol' do
      subject.send_exited_event(0)
      expect(event_named('exited')).not_to be_nil
      expect(event_named('exited')['body']['exitCode']).to eq(0)
    end
  end

  describe '#send_output_event' do
    it 'sends an output event via protocol' do
      subject.send_output_event('category' => 'console', 'output' => 'hello')
      expect(event_named('output')).not_to be_nil
    end
  end

  describe '#send_stopped_event' do
    it 'sends a stopped event via protocol' do
      subject.send_stopped_event('breakpoint', 'threadId' => 1)
      ev = event_named('stopped')
      expect(ev).not_to be_nil
      expect(ev['body']['reason']).to eq('breakpoint')
    end
  end

  describe '#send_termination_event' do
    it 'sends a terminated event via protocol' do
      subject.send_termination_event
      expect(event_named('terminated')).not_to be_nil
    end
  end

  describe '#send_thread_event' do
    it 'sends a thread event via protocol' do
      subject.send_thread_event('started', 42)
      ev = event_named('thread')
      expect(ev).not_to be_nil
      expect(ev['body']['reason']).to eq('started')
      expect(ev['body']['threadId']).to eq(42)
    end
  end

  # --- Request handlers ---

  describe '#request_configurationdone' do
    it 'returns a success response' do
      protocol.receive_mock_string(client.configuration_done_request(1))
      resp = response_for(1)
      expect(resp).not_to be_nil
      expect(resp['success']).to be true
    end
  end

  describe '#request_disconnect' do
    it 'closes the connection' do
      expect(protocol).to receive(:close_connection)
      protocol.receive_mock_string(client.disconnect_request(1))
    end
  end

  describe '#request_threads' do
    context 'when puppet_thread_id is nil' do
      it 'returns a failure response' do
        protocol.receive_mock_string(client.threads_request(1))
        resp = response_for(1)
        expect(resp).not_to be_nil
        expect(resp['success']).to be false
      end
    end

    context 'when puppet_thread_id is set' do
      before(:each) { debug_session.initialize_session }

      it 'returns a success response with thread list' do
        protocol.receive_mock_string(client.threads_request(1))
        resp = response_for(1)
        expect(resp).not_to be_nil
        expect(resp['success']).to be true
        expect(resp['body']['threads']).not_to be_empty
      end
    end
  end

  describe '#request_stacktrace' do
    context 'when puppet_thread_id is nil' do
      it 'returns a failure response' do
        protocol.receive_mock_string(client.stacktrace_request(1, 0))
        resp = response_for(1)
        expect(resp['success']).to be false
      end
    end

    context 'when puppet_thread_id matches' do
      before(:each) { debug_session.initialize_session }

      it 'returns a success response' do
        thread_id = debug_session.puppet_thread_id
        protocol.receive_mock_string(client.stacktrace_request(1, thread_id))
        resp = response_for(1)
        expect(resp['success']).to be true
      end
    end
  end

  describe '#request_scopes' do
    context 'when session is not active' do
      it 'returns a failure response' do
        protocol.receive_mock_string(client.scopes_request(1, 0))
        resp = response_for(1)
        expect(resp['success']).to be false
      end
    end

    context 'when session is active' do
      before(:each) do
        debug_session.flow_control.assert_flag(:puppet_started)
      end

      it 'returns a success response' do
        protocol.receive_mock_string(client.scopes_request(1, 0))
        resp = response_for(1)
        expect(resp['success']).to be true
      end
    end
  end

  describe '#request_variables' do
    context 'when session is not active' do
      it 'returns a failure response' do
        protocol.receive_mock_string(client.variables_request(1, 0))
        resp = response_for(1)
        expect(resp['success']).to be false
      end
    end

    context 'when session is active' do
      before(:each) do
        debug_session.flow_control.assert_flag(:puppet_started)
      end

      it 'returns a success response' do
        protocol.receive_mock_string(client.variables_request(1, 0))
        resp = response_for(1)
        expect(resp['success']).to be true
      end
    end
  end

  describe '#request_evaluate' do
    context 'when session is not active' do
      it 'returns a failure response' do
        protocol.receive_mock_string(client.evaluate_request(1, 'notice("hi")'))
        resp = response_for(1)
        expect(resp['success']).to be false
      end
    end
  end

  describe '#request_next' do
    context 'when puppet_thread_id is nil' do
      it 'returns a failure response' do
        protocol.receive_mock_string(client.next_request(1, 0))
        resp = response_for(1)
        expect(resp['success']).to be false
      end
    end

    context 'when puppet_thread_id matches' do
      before(:each) { debug_session.initialize_session }

      it 'returns a success response' do
        thread_id = debug_session.puppet_thread_id
        debug_session.puppet_session_state.saved.update!(pops_depth_level: 0)
        protocol.receive_mock_string(client.next_request(1, thread_id))
        resp = response_for(1)
        expect(resp['success']).to be true
      end
    end
  end

  describe '#request_stepin' do
    context 'when puppet_thread_id is nil' do
      it 'returns a failure response' do
        protocol.receive_mock_string(client.stepin_request(1, 0))
        resp = response_for(1)
        expect(resp['success']).to be false
      end
    end

    context 'when puppet_thread_id matches' do
      before(:each) { debug_session.initialize_session }

      it 'returns a success response' do
        thread_id = debug_session.puppet_thread_id
        protocol.receive_mock_string(client.stepin_request(1, thread_id))
        resp = response_for(1)
        expect(resp['success']).to be true
      end
    end
  end

  describe '#request_stepout' do
    context 'when puppet_thread_id is nil' do
      it 'returns a failure response' do
        protocol.receive_mock_string(client.stepout_request(1, 0))
        resp = response_for(1)
        expect(resp['success']).to be false
      end
    end

    context 'when puppet_thread_id matches' do
      before(:each) { debug_session.initialize_session }

      it 'returns a success response' do
        thread_id = debug_session.puppet_thread_id
        debug_session.puppet_session_state.saved.update!(pops_depth_level: 0)
        protocol.receive_mock_string(client.stepout_request(1, thread_id))
        resp = response_for(1)
        expect(resp['success']).to be true
      end
    end
  end

  describe '#request_setbreakpoints' do
    it 'returns a success response with breakpoints' do
      req = JSON.generate({
        'command' => 'setBreakpoints',
        'type' => 'request',
        'seq' => 1,
        'arguments' => {
          'source' => { 'path' => '/no/such/file.pp' },
          'breakpoints' => [{ 'line' => 1 }]
        }
      })
      protocol.receive_mock_string(req)
      resp = response_for(1)
      expect(resp['success']).to be true
      expect(resp['body']['breakpoints']).not_to be_nil
    end
  end

  describe '#request_setfunctionbreakpoints' do
    it 'returns a success response with breakpoints' do
      req = JSON.generate({
        'command' => 'setFunctionBreakpoints',
        'type' => 'request',
        'seq' => 1,
        'arguments' => {
          'breakpoints' => [{ 'name' => 'mymod::myfunc' }]
        }
      })
      protocol.receive_mock_string(req)
      resp = response_for(1)
      expect(resp['success']).to be true
    end
  end

  describe '#request_initialize' do
    before(:each) { allow(subject).to receive(:sleep) }

    it 'sends a capability response synchronously' do
      protocol.receive_mock_string(client.initialize_request(1))
      resp = response_for(1)
      expect(resp).not_to be_nil
      expect(resp['body']['supportsConfigurationDoneRequest']).to be true
    end

    it 'sends an initialized event' do
      protocol.receive_mock_string(client.initialize_request(1))
      expect(event_named('initialized')).not_to be_nil
    end
  end
end
