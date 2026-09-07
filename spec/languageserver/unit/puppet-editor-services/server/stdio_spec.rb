require 'spec_helper'
require 'puppet_editor_services/server/stdio'

describe 'PuppetEditorServices::Server::Stdio' do
  let(:server_options) { { servicename: 'TEST' } }
  let(:protocol_options) { { class: PuppetEditorServices::Protocol::JsonRPC } }
  let(:handler_options) { { class: MockMessageHandler } }
  let(:subject) { PuppetEditorServices::Server::Stdio.new(server_options, protocol_options, handler_options) }

  describe '#name' do
    it 'returns STDIOSRV' do
      expect(subject.name).to eq('STDIOSRV')
    end
  end

  describe '#stop' do
    it 'sets exiting to true' do
      expect(subject.exiting).to be(false)
      subject.stop
      expect(subject.exiting).to be(true)
    end
  end

  describe '#close_connection' do
    it 'delegates to stop' do
      expect(subject).to receive(:stop)
      subject.close_connection
    end
  end

  describe '#connection' do
    context 'when no client connection has been established' do
      it 'returns nil' do
        expect(subject.connection('any_id')).to be_nil
      end
    end

    context 'when a client connection exists with a matching id' do
      let(:mock_conn) { double('connection', id: 'conn_42') }

      before { subject.instance_variable_set(:@client_connection, mock_conn) }

      it 'returns the connection' do
        expect(subject.connection('conn_42')).to eq(mock_conn)
      end
    end

    context 'when a client connection exists but id does not match' do
      let(:mock_conn) { double('connection', id: 'conn_42') }

      before { subject.instance_variable_set(:@client_connection, mock_conn) }

      it 'returns nil' do
        expect(subject.connection('other_id')).to be_nil
      end
    end
  end

  describe '#pipe_is_readable?' do
    let(:mock_pipe) { double('pipe') }

    it 'returns true when the pipe is ready' do
      allow(IO).to receive(:select).with([mock_pipe], [], [], 0.5).and_return([[mock_pipe], [], []])
      expect(subject.pipe_is_readable?(mock_pipe)).to be(true)
    end

    it 'returns false when IO.select times out' do
      allow(IO).to receive(:select).with([mock_pipe], [], [], 0.5).and_return(nil)
      expect(subject.pipe_is_readable?(mock_pipe)).to be_falsey
    end

    it 'accepts a custom timeout' do
      allow(IO).to receive(:select).with([mock_pipe], [], [], 2.0).and_return(nil)
      expect(subject.pipe_is_readable?(mock_pipe, 2.0)).to be_falsey
    end
  end

  describe '#read_from_pipe' do
    let(:mock_pipe) { double('pipe') }

    context 'when the pipe is not readable' do
      before { allow(subject).to receive(:pipe_is_readable?).and_return(false) }

      it 'does not yield' do
        yielded = false
        subject.read_from_pipe(mock_pipe) { yielded = true }
        expect(yielded).to be(false)
      end

      it 'returns nil' do
        expect(subject.read_from_pipe(mock_pipe) { }).to be_nil
      end
    end

    context 'when the pipe is readable and returns data' do
      before do
        allow(subject).to receive(:pipe_is_readable?).and_return(true)
        allow(mock_pipe).to receive(:readpartial).and_return('some data')
      end

      it 'yields the data' do
        received = nil
        subject.read_from_pipe(mock_pipe) { |data| received = data }
        expect(received).to eq('some data')
      end
    end

    context 'when the pipe raises EOFError' do
      before do
        allow(subject).to receive(:pipe_is_readable?).and_return(true)
        allow(mock_pipe).to receive(:readpartial).and_raise(EOFError)
        allow(PuppetEditorServices).to receive(:log_message)
      end

      it 'does not raise' do
        expect { subject.read_from_pipe(mock_pipe) { } }.not_to raise_error
      end

      it 'stops the server' do
        expect(subject).to receive(:stop)
        subject.read_from_pipe(mock_pipe) { }
      end
    end
  end
end
