require 'spec_helper'

require 'puppet_editor_services/protocol/json_rpc'

describe 'PuppetEditorServices::Protocol::JsonRPC' do
  let(:server) do
    MockServer.new(
      {},
      {},
      { :class => PuppetEditorServices::Protocol::JsonRPC },
      { :class => MockMessageHandler }
    )
  end
  let(:subject) { server.protocol_object }
  let(:message_handler) { server.handler_object }

  RSpec::Matchers.define :a_request_of do |method_name|
    match do |actual|
      actual.is_a?(::PuppetEditorServices::Protocol::JsonRPCMessages::RequestMessage) &&
      actual.rpc_method == method_name
    end
  end

  RSpec::Matchers.define :a_notification_of do |method_name|
    match do |actual|
      actual.is_a?(::PuppetEditorServices::Protocol::JsonRPCMessages::NotificationMessage) &&
      actual.rpc_method == method_name
    end
  end

  RSpec::Matchers.define :a_successful_response_from do |request_id|
    match do |actual|
      actual.is_a?(::PuppetEditorServices::Protocol::JsonRPCMessages::ResponseMessage) &&
      actual.is_successful &&
      actual.id == request_id
    end
  end

  RSpec::Matchers.define :a_context_with_request_of do |method_name|
    match do |actual|
      actual[:request].is_a?(::PuppetEditorServices::Protocol::JsonRPCMessages::RequestMessage) &&
      actual[:request].rpc_method == method_name
    end
  end

  context 'Given a valid JSON Request string' do
    let(:data) { "Content-Length: 67\r\n\r\n" + '{"jsonrpc":"2.0","id":1,"method":"puppet/getVersion","params":null}' }

    it 'should call the appropriate request method on the message handler' do
      expect(message_handler).to receive(:handle).with(a_request_of('puppet/getVersion'))
      subject.receive_data(data)
    end
  end

  context 'Given a valid JSON Notification string' do
    let(:data) { "Content-Length: 52\r\n\r\n" + '{"jsonrpc":"2.0","method":"initialized","params":{}}' }

    it 'should call the the message handler' do
      expect(message_handler).to receive(:handle).with(a_notification_of('initialized'))
      subject.receive_data(data)
    end
  end

  context 'Given a valid JSON Response string' do
    let(:data) { "Content-Length: 57\r\n\r\n" + '{"jsonrpc":"2.0","id":1,"result":"success","params":null}' }
    let(:client_req_id) { 1 }

    it 'should call the appropriate response method on the message handler' do
      # Force the request id to what we want to test for.
      allow(subject).to receive(:client_request_id!).and_return(client_req_id)
      # Send a request to the client
      subject.send_client_request('mock', {})
      # Mimic a repsonse from the client
      expect(message_handler).to receive(:handle).with(
        a_successful_response_from(client_req_id),
        a_context_with_request_of('mock')
      )
      subject.receive_data(data)
    end
  end

  context 'Given a JSON Response that has no matching request from the server' do
    let(:data) { "Content-Length: 57\r\n\r\n" + '{"jsonrpc":"2.0","id":1,"result":"success","params":null}' }

    it 'should ignore the response' do
      expect(message_handler).to_not receive(:handle)
      subject.receive_data(data)
    end
  end

  context 'Given a JSON Response that appears twice' do
    let(:client_req_id) { 1 }
    let(:data) { "Content-Length: 57\r\n\r\n" + '{"jsonrpc":"2.0","id":1,"result":"success","params":null}' }

    it 'should call the appropriate response method on the message handler only once' do
      # Force the request id to what we want to test for.
      allow(subject).to receive(:client_request_id!).and_return(client_req_id)
      # Send a request to the client
      subject.send_client_request('mock', {})
      # Mimic a repsonse from the client, only once
      expect(message_handler).to receive(:handle).with(
        a_successful_response_from(client_req_id),
        a_context_with_request_of('mock')
      ).once
      subject.receive_data(data)
      subject.receive_data(data)
    end
  end
end
