require 'spec_debug_helper'
require 'spec_debug_client'
require 'json'

# Helper methods that look at the stubbed message for various
# messages in the queue.
def data_from_request_seq_id(obj, request_seq_id)
  obj.sent_objects.find { |item| item['request_seq'] == request_seq_id}
end

def data_from_event_name(obj, event_name)
  obj.sent_objects.find { |item| item['type'] == 'event' && item['event'] == event_name}
end

describe 'PuppetDebugServer::MessageHandler' do
  let(:server) do
    MockServer.new(
      {},
      { :class => MockConnection },
      { :class => MockProtocol },
      { :class => PuppetDebugServer::MessageHandler }
    )
  end
  let(:subject) { server.handler_object }
  let(:protocol) { server.protocol_object }
  let(:connection) { server.connection_object }
  let(:client) { DebugClient.new }

  context 'During initial session setup' do
    it 'should respond with the correct capabilities' do
      protocol.receive_mock_string(client.initialize_request)

      response = data_from_request_seq_id(connection, 1)
      expect(response['body']['supportsConfigurationDoneRequest']).to be true
      expect(response['body']['supportsFunctionBreakpoints']).to be true
      expect(response['body']['supportsRestartRequest']).to be false
      expect(response['body']['supportsStepBack']).to be false
      expect(response['body']['supportsSetVariable']).to be true
      expect(response['body']['supportsStepInTargetsRequest']).to be false
      expect(response['body']['supportedChecksumAlgorithms']).to eq([])
    end

    it 'should respond with an Initialized event' do
      protocol.receive_mock_string(client.initialize_request)

      response = data_from_event_name(connection, 'initialized')
      expect(response).to_not be nil
    end

    it 'should respond with failures for debug session commands' do
      protocol.receive_mock_string(client.initialize_request)
      protocol.receive_mock_string(client.threads_request(2))
      protocol.receive_mock_string(client.stacktrace_request(3))
      protocol.receive_mock_string(client.scopes_request(4))
      protocol.receive_mock_string(client.variables_request(5))
      protocol.receive_mock_string(client.evaluate_request(6))
      protocol.receive_mock_string(client.stepin_request(7))
      protocol.receive_mock_string(client.stepout_request(8))
      protocol.receive_mock_string(client.next_request(9))

      {
        2 => 'threads',
        3 => 'stackTrace',
        4 => 'scopes',
        5 => 'variables',
        6 => 'evaluate',
        7 => 'stepIn',
        8 => 'stepOut',
        9 => 'next',
      }.each do |seq_id, command|
        response = data_from_request_seq_id(connection, seq_id)
        expect(response).to_not be nil
        expect(response['success']).to be false
        expect(response['command']).to eq(command)
      end
    end
  end

  context 'Receiving a disconnect request' do
    it 'should close the connection' do
      expect(connection).to receive(:close)
      protocol.receive_mock_string(client.initialize_request)
      protocol.receive_mock_string(client.disconnect_request(2))
    end
  end
end
