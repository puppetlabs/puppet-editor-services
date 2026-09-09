require 'spec_helper'
require 'puppet_editor_services/connection/base'

describe 'PuppetEditorServices::Connection::Base' do
  let(:server) do
    MockServer.new(
      {},
      { class: PuppetEditorServices::Connection::Base },
      { class: PuppetEditorServices::Protocol::JsonRPC },
      { class: MockMessageHandler }
    )
  end
  let(:subject) { server.connection_object }

  before { allow(PuppetEditorServices).to receive(:log_message) }

  describe '#error?' do
    it 'returns false by default' do
      expect(subject.error?).to be(false)
    end
  end

  describe '#send_data' do
    it 'returns false by default' do
      expect(subject.send_data('data')).to be(false)
    end
  end

  describe '#close_after_writing' do
    it 'returns true by default' do
      expect(subject.close_after_writing).to be(true)
    end
  end

  describe '#close' do
    it 'returns true by default' do
      expect(subject.close).to be(true)
    end
  end

  describe '#id' do
    it 'returns a string' do
      expect(subject.id).to be_a(String)
    end

    it 'is based on object_id' do
      expect(subject.id).to eq(subject.object_id.to_s)
    end
  end

  describe '#post_init' do
    it 'does not raise' do
      expect { subject.post_init }.not_to raise_error
    end

    it 'logs a connection message via the server' do
      expect(PuppetEditorServices).to receive(:log_message).with(:debug, /connected/)
      subject.post_init
    end
  end

  describe '#unbind' do
    it 'does not raise' do
      expect { subject.unbind }.not_to raise_error
    end

    it 'logs a disconnection message via the server' do
      expect(PuppetEditorServices).to receive(:log_message).with(:debug, /disconnected/)
      subject.unbind
    end
  end

  describe '#receive_data' do
    it 'delegates to the protocol' do
      expect(subject.protocol).to receive(:receive_data).with('data')
      subject.receive_data('data')
    end

    context 'when the protocol raises a StandardError' do
      before do
        allow(subject.protocol).to receive(:receive_data).and_raise(StandardError, 'mock error')
      end

      it 'does not propagate the error' do
        expect { subject.receive_data('data') }.not_to raise_error
      end

      it 'logs the error via the server' do
        expect(PuppetEditorServices).to receive(:log_message).with(:debug, /mock error/)
        subject.receive_data('data')
      end
    end
  end
end
