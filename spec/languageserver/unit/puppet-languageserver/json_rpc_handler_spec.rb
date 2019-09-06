require 'spec_helper'

describe 'PuppetLanguageServer::JSONRPCHandler' do
  let(:connection) { MockConnection.new }
  let(:message_router) { MockMessageRouter.new }
  let(:subject_options) {{
    connection: connection,
    message_router: message_router
  }}
  let(:subject) { PuppetLanguageServer::JSONRPCHandler.new(subject_options) }

  context 'Given a valid JSON Request string' do
    let(:data) { "Content-Length: 67\r\n\r\n" + '{"jsonrpc":"2.0","id":1,"method":"puppet/getVersion","params":null}' }

    it 'should call receive_request on the message router' do
      expect(message_router).to receive(:receive_request)
      subject.receive_data(data)
    end
  end

  context 'Given a valid JSON Notification string' do
    let(:data) { "Content-Length: 52\r\n\r\n" + '{"jsonrpc":"2.0","method":"initialized","params":{}}' }

    it 'should call receive_notification on the message router' do
      expect(message_router).to receive(:receive_notification)
      subject.receive_data(data)
    end
  end

  context 'Given a valid JSON Response string' do
    let(:data) { "Content-Length: 57\r\n\r\n" + '{"jsonrpc":"2.0","id":1,"result":"success","params":null}' }

    it 'should call receive_response on the message router' do
      # Force the request id to what we want to test for.
      allow(subject).to receive(:client_request_id!).and_return(1)
      # Send a request to the client
      subject.send_client_request('mock', {})
      # Mimic a repsonse from the client
      expect(message_router).to receive(:receive_response)
      subject.receive_data(data)
    end
  end

  context 'Given a JSON Response that has no matching request from the server' do
    let(:data) { "Content-Length: 57\r\n\r\n" + '{"jsonrpc":"2.0","id":1,"result":"success","params":null}' }

    it 'should ignore the response' do
      expect(message_router).to_not receive(:receive_request)
      expect(message_router).to_not receive(:receive_notification)
      expect(message_router).to_not receive(:receive_response)
      subject.receive_data(data)
    end
  end

  context 'Given a JSON Response that appears twice' do
    let(:data) { "Content-Length: 57\r\n\r\n" + '{"jsonrpc":"2.0","id":1,"result":"success","params":null}' }

    it 'should call receive_response on the message router only once' do
      # Force the request id to what we want to test for.
      allow(subject).to receive(:client_request_id!).and_return(1)
      # Send a request to the client
      subject.send_client_request('mock', {})
      # Mimic a repsonse from the client, only once
      expect(message_router).to receive(:receive_response).once
      expect(message_router).to_not receive(:receive_request)
      expect(message_router).to_not receive(:receive_notification)
      subject.receive_data(data)
      subject.receive_data(data)
    end
  end
end
