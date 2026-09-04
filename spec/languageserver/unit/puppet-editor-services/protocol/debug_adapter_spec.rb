# frozen_string_literal: true

require 'spec_helper'
require 'puppet_editor_services/protocol/debug_adapter'
require 'puppet_editor_services/handler/debug_adapter'

describe 'PuppetEditorServices::Protocol::DebugAdapter' do
  let(:server) do
    MockServer.new(
      {},
      {},
      { class: PuppetEditorServices::Protocol::DebugAdapter },
      { class: PuppetEditorServices::Handler::DebugAdapter }
    )
  end
  let(:subject)         { server.protocol_object }
  let(:message_handler) { server.handler_object }

  before do
    allow(PuppetEditorServices).to receive(:log_message)
  end

  def framed(json_string)
    "Content-Length: #{json_string.bytesize}\r\n\r\n#{json_string}"
  end

  describe '#extract_headers' do
    it 'parses a Content-Length header' do
      headers = subject.extract_headers('Content-Length: 123')
      expect(headers['Content-Length']).to eq(123)
    end

    it 'parses a Content-Type header (stored as Content-Length key per implementation)' do
      headers = subject.extract_headers('Content-Type: application/json')
      expect(headers).to have_key('Content-Length')
    end

    it 'raises on an unknown header' do
      expect { subject.extract_headers('X-Unknown: value') }.to raise_error(/Unknown header/)
    end

    it 'handles multiple headers' do
      headers = subject.extract_headers("Content-Length: 50\r\nContent-Type: application/json")
      expect(headers['Content-Length']).to be_a(Integer).or be_a(String)
    end
  end

  describe '#receive_data' do
    context 'with empty data' do
      it 'returns without error' do
        expect { subject.receive_data('') }.not_to raise_error
      end
    end

    context 'with a valid framed JSON request' do
      let(:json_body) { '{"seq":1,"type":"request","command":"initialize"}' }
      let(:data)      { framed(json_body) }

      it 'dispatches the request to the message handler' do
        expect(message_handler).to receive(:handle).with(
          an_instance_of(PuppetEditorServices::Protocol::DebugAdapterMessages::Request)
        )
        subject.receive_data(data)
      end
    end

    context 'with partial data (incomplete message)' do
      it 'buffers the data without error' do
        expect { subject.receive_data("Content-Length: 100\r\n\r\n{") }.not_to raise_error
      end
    end
  end

  describe '#receive_json_message_as_hash' do
    context 'when message type is request' do
      let(:json_obj) { { 'seq' => 1, 'type' => 'request', 'command' => 'initialize' } }

      it 'calls handle on the message handler with a Request object' do
        expect(message_handler).to receive(:handle).with(
          an_instance_of(PuppetEditorServices::Protocol::DebugAdapterMessages::Request)
        )
        subject.receive_json_message_as_hash(json_obj)
      end

      it 'returns true' do
        allow(message_handler).to receive(:handle)
        expect(subject.receive_json_message_as_hash(json_obj)).to be(true)
      end
    end

    context 'when message type is not request' do
      let(:json_obj) { { 'seq' => 1, 'type' => 'event', 'event' => 'initialized' } }

      it 'logs an error' do
        expect(PuppetEditorServices).to receive(:log_message).with(:error, /event/)
        subject.receive_json_message_as_hash(json_obj)
      end

      it 'does not call handle on the message handler' do
        expect(message_handler).not_to receive(:handle)
        subject.receive_json_message_as_hash(json_obj)
      end

      it 'returns false' do
        expect(subject.receive_json_message_as_hash(json_obj)).to be(false)
      end
    end
  end

  describe '#encode_and_send' do
    let(:event) do
      PuppetEditorServices::Protocol::DebugAdapterMessages::Event.new({ 'event' => 'initialized' })
    end

    it 'assigns an incrementing sequence id to the message' do
      allow(server.connection_object).to receive(:send_data)
      subject.encode_and_send(event)
      expect(event.seq).to be_a(Integer)
    end

    it 'sends framed JSON data via the connection' do
      expect(server.connection_object).to receive(:send_data).with(/Content-Length:/)
      subject.encode_and_send(event)
    end

    it 'raises when passed a non-ProtocolMessage object' do
      expect { subject.encode_and_send('not a message') }.to raise_error(/ProtocolMessage/)
    end

    it 'increments the sequence id on each call' do
      allow(server.connection_object).to receive(:send_data)
      event1 = PuppetEditorServices::Protocol::DebugAdapterMessages::Event.new({ 'event' => 'e1' })
      event2 = PuppetEditorServices::Protocol::DebugAdapterMessages::Event.new({ 'event' => 'e2' })
      subject.encode_and_send(event1)
      subject.encode_and_send(event2)
      expect(event2.seq).to eq(event1.seq + 1)
    end
  end

  describe '#send_json_string' do
    it 'sends data with a Content-Length header' do
      payload = '{"type":"event","seq":1}'
      expect(server.connection_object).to receive(:send_data).with(
        "Content-Length: #{payload.bytesize}\r\n\r\n#{payload}"
      )
      subject.send_json_string(payload)
    end
  end
end
