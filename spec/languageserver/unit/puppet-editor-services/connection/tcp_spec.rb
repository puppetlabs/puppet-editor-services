require 'spec_helper'
require 'puppet_editor_services/connection/tcp'

describe 'PuppetEditorServices::Connection::Tcp' do
  let(:mock_socket) { double('socket', write: nil, flush: nil) }
  let(:server) do
    s = MockServer.new(
      {},
      {},
      { class: PuppetEditorServices::Protocol::JsonRPC },
      { class: MockMessageHandler }
    )
    allow(s).to receive(:remove_connection_async)
    s
  end
  # Instantiate directly since MockServer only supports single-arg connection constructors
  let(:subject) { PuppetEditorServices::Connection::Tcp.new(server, mock_socket) }

  describe '#send_data' do
    context 'when the socket is set' do
      it 'writes data to the socket' do
        expect(mock_socket).to receive(:write).with('data')
        subject.send_data('data')
      end

      it 'returns true' do
        expect(subject.send_data('data')).to be(true)
      end
    end

    context 'when the socket is nil' do
      before { subject.socket = nil }

      it 'returns false without raising' do
        expect(subject.send_data('data')).to be(false)
      end
    end
  end

  describe '#close_after_writing' do
    it 'flushes the socket' do
      expect(mock_socket).to receive(:flush)
      subject.close_after_writing
    end

    it 'requests async connection removal' do
      expect(server).to receive(:remove_connection_async).with(mock_socket)
      subject.close_after_writing
    end

    it 'returns true' do
      expect(subject.close_after_writing).to be(true)
    end
  end

  describe '#close' do
    it 'requests async connection removal' do
      expect(server).to receive(:remove_connection_async).with(mock_socket)
      subject.close
    end

    it 'returns true' do
      expect(subject.close).to be(true)
    end
  end
end
