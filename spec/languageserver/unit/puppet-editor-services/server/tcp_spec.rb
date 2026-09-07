require 'spec_helper'
require 'puppet_editor_services/server/tcp'

describe 'PuppetEditorServices::Server::Tcp' do
  let(:mock_tcp_server) { double('TCPServer', local_address: double(ip_port: 12345), close: nil) }

  before do
    allow(TCPServer).to receive(:new).and_return(mock_tcp_server)
  end

  let(:server_options) { { servicename: 'TEST', ipaddress: 'localhost', port: 0 } }
  let(:protocol_options) { { class: PuppetEditorServices::Protocol::JsonRPC } }
  let(:handler_options) { { class: MockMessageHandler } }
  let(:subject) { PuppetEditorServices::Server::Tcp.new(server_options, protocol_options, handler_options) }

  before do
    # Force eager subject creation so that initialization events are added before
    # individual tests clear the queue. Without this, lazy evaluation means
    # subject creation (which adds a log callback event) happens after the clear.
    subject
    PuppetEditorServices::Server::Tcp.e_locker.synchronize { PuppetEditorServices::Server::Tcp.events.clear }
  end

  after do
    # Clean up class-level state between tests
    PuppetEditorServices::Server::Tcp.e_locker.synchronize { PuppetEditorServices::Server::Tcp.events.clear }
    PuppetEditorServices::Server::Tcp.s_locker.synchronize { PuppetEditorServices::Server::Tcp.services.clear }
    PuppetEditorServices::Server::Tcp.c_locker.synchronize { PuppetEditorServices::Server::Tcp.io_connection_dic.clear }
  end

  describe '#name' do
    it 'returns TCPSRV' do
      expect(subject.name).to eq('TCPSRV')
    end
  end

  describe '#events?' do
    it 'returns false when there are no events' do
      PuppetEditorServices::Server::Tcp.e_locker.synchronize { PuppetEditorServices::Server::Tcp.events.clear }
      expect(subject.events?).to be(false)
    end

    it 'returns true when there are events' do
      PuppetEditorServices::Server::Tcp.e_locker.synchronize { PuppetEditorServices::Server::Tcp.events << [proc {}, []] }
      expect(subject.events?).to be(true)
    end
  end

  describe '#run_async' do
    it 'adds the block to the events queue and returns true' do
      PuppetEditorServices::Server::Tcp.e_locker.synchronize { PuppetEditorServices::Server::Tcp.events.clear }
      result = subject.run_async { 'work' }
      expect(result).to be(true)
      event_count = PuppetEditorServices::Server::Tcp.e_locker.synchronize { PuppetEditorServices::Server::Tcp.events.count }
      expect(event_count).to eq(1)
    end

    it 'returns false when no block is given' do
      expect(subject.run_async).to be(false)
    end
  end

  describe '#fire_event' do
    it 'returns false when there are no events' do
      PuppetEditorServices::Server::Tcp.e_locker.synchronize { PuppetEditorServices::Server::Tcp.events.clear }
      expect(subject.fire_event).to be(false)
    end

    it 'calls the event and returns true' do
      called = false
      PuppetEditorServices::Server::Tcp.e_locker.synchronize do
        PuppetEditorServices::Server::Tcp.events << [proc { called = true }, []]
      end
      result = subject.fire_event
      expect(result).to be(true)
      expect(called).to be(true)
    end
  end

  describe '#remove_connection_async' do
    it 'pushes a remove_connection callback event' do
      PuppetEditorServices::Server::Tcp.e_locker.synchronize { PuppetEditorServices::Server::Tcp.events.clear }
      mock_io = double('io')
      subject.remove_connection_async(mock_io)
      event_count = PuppetEditorServices::Server::Tcp.e_locker.synchronize { PuppetEditorServices::Server::Tcp.events.count }
      expect(event_count).to eq(1)
    end
  end

  describe '#stop_connections' do
    it 'closes all active connections and clears the connection dict' do
      mock_io = double('io')
      allow(mock_io).to receive(:close)
      PuppetEditorServices::Server::Tcp.c_locker.synchronize do
        PuppetEditorServices::Server::Tcp.io_connection_dic[mock_io] = { handler: double('conn') }
      end

      expect(mock_io).to receive(:close)
      subject.stop_connections

      count = PuppetEditorServices::Server::Tcp.c_locker.synchronize { PuppetEditorServices::Server::Tcp.io_connection_dic.count }
      expect(count).to eq(0)
    end
  end

  describe '#connection' do
    it 'returns nil when no connections exist' do
      PuppetEditorServices::Server::Tcp.c_locker.synchronize { PuppetEditorServices::Server::Tcp.io_connection_dic.clear }
      expect(subject.connection('any_id')).to be_nil
    end

    it 'returns the matching connection handler' do
      mock_conn = double('conn', id: 'conn_99')
      mock_io = double('io')
      PuppetEditorServices::Server::Tcp.c_locker.synchronize do
        PuppetEditorServices::Server::Tcp.io_connection_dic[mock_io] = { handler: mock_conn }
      end

      expect(subject.connection('conn_99')).to eq(mock_conn)
    end

    it 'returns nil when no connection id matches' do
      mock_conn = double('conn', id: 'conn_99')
      mock_io = double('io')
      PuppetEditorServices::Server::Tcp.c_locker.synchronize do
        PuppetEditorServices::Server::Tcp.io_connection_dic[mock_io] = { handler: mock_conn }
      end

      expect(subject.connection('other_id')).to be_nil
    end
  end

  describe '#stop_services' do
    it 'closes all services and clears the services hash' do
      allow(mock_tcp_server).to receive(:close)
      allow(PuppetEditorServices).to receive(:log_message)

      PuppetEditorServices::Server::Tcp.s_locker.synchronize do
        PuppetEditorServices::Server::Tcp.services[mock_tcp_server] = { hostname: 'localhost', port: 12345 }
      end

      subject.stop_services

      count = PuppetEditorServices::Server::Tcp.s_locker.synchronize { PuppetEditorServices::Server::Tcp.services.count }
      expect(count).to eq(0)
    end
  end
end
