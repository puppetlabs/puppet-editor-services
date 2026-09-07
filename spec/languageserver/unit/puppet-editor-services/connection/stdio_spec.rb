require 'spec_helper'
require 'puppet_editor_services/connection/stdio'

describe 'PuppetEditorServices::Connection::Stdio' do
  let(:mock_stdout) { double('stdout', write: nil, flush: nil) }
  let(:server) do
    s = MockServer.new(
      {},
      { class: PuppetEditorServices::Connection::Stdio },
      { class: PuppetEditorServices::Protocol::JsonRPC },
      { class: MockMessageHandler }
    )
    allow(s).to receive(:close_connection)
    s
  end
  let(:subject) { server.connection_object }

  before do
    # rubocop:disable Style/GlobalVars
    @original_stdout = $editor_services_stdout
    $editor_services_stdout = mock_stdout
    # rubocop:enable Style/GlobalVars
  end

  after do
    # rubocop:disable Style/GlobalVars
    $editor_services_stdout = @original_stdout
    # rubocop:enable Style/GlobalVars
  end

  describe '#send_data' do
    it 'writes data to $editor_services_stdout' do
      expect(mock_stdout).to receive(:write).with('data')
      subject.send_data('data')
    end

    it 'returns true' do
      expect(subject.send_data('data')).to be(true)
    end
  end

  describe '#close_after_writing' do
    it 'flushes $editor_services_stdout' do
      expect(mock_stdout).to receive(:flush)
      subject.close_after_writing
    end

    it 'closes the server connection' do
      expect(server).to receive(:close_connection)
      subject.close_after_writing
    end

    it 'returns true' do
      expect(subject.close_after_writing).to be(true)
    end
  end

  describe '#close' do
    it 'closes the server connection' do
      expect(server).to receive(:close_connection)
      subject.close
    end

    it 'returns true' do
      expect(subject.close).to be(true)
    end
  end
end
