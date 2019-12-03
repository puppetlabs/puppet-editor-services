require 'spec_helper'

class SuccessStatus
  def exitstatus
    0
  end
end

describe 'sidecar_queue' do
  let(:server) do
    MockServer.new({}, {}, {}, { :class => PuppetLanguageServer::MessageHandler })
  end
  let(:mock_connection) { server.connection_object }
  let(:connection_id) { 'mock_conn_id' }
  let(:cache) { PuppetLanguageServer::SessionState::ObjectCache.new }
  let(:session_state) { PuppetLanguageServer::ClientSessionState.new(server.handler_object, :object_cache => cache) }
  let(:subject) { PuppetLanguageServer::GlobalQueues::SidecarQueue.new }

  before(:each) do
    # Mock a connection and session state
    allow(subject).to receive(:connection_from_connection_id).with(connection_id).and_return(mock_connection)
    allow(subject).to receive(:sidecar_args_from_connection).with(mock_connection).and_return([])
    allow(subject).to receive(:session_state_from_connection).with(mock_connection).and_return(session_state)
  end

  describe 'SidecarQueueJob' do
    it 'should only contain the action name connection id in the key' do
      job = PuppetLanguageServer::GlobalQueues::SidecarQueueJob.new('action', ['additional'], true, connection_id)
      expect(job.key).to eq("action-#{connection_id}")
    end
  end

  describe '#enqueue' do
    let(:action1) { 'default_classes' }
    let(:action2) { 'default_types' }
    let(:additional_args1) { [] }
    let(:additional_args2) { [] }

    before(:each) do
      allow(subject).to receive(:execute_job).and_raise("#{self.class}.execute_job mock should not be called")
    end

    context 'for a single item in the queue' do
      it 'should call the synchronous method' do
        expect(subject).to receive(:execute_job).with(having_attributes(
          :action          => action1,
          :additional_args => additional_args1,
          :handle_errors   => false,
          :connection_id   => connection_id
        )).and_return(true)

        subject.enqueue(action1, additional_args1, false, connection_id)
        subject.drain_queue
      end
    end

    context 'for multiple items in the queue' do
      it 'should process all unique actions' do
        expect(subject).to receive(:execute_job).with(having_attributes(
          :action          => action1,
          :additional_args => additional_args1,
          :handle_errors   => false,
          :connection_id   => connection_id
        )).and_return(true)

        expect(subject).to receive(:execute_job).with(having_attributes(
          :action          => action2,
          :additional_args => additional_args2,
          :handle_errors   => false,
          :connection_id   => connection_id
        )).and_return(true)

        subject.enqueue(action1, additional_args1, false, connection_id)
        subject.enqueue(action2, additional_args2, false, connection_id)
        subject.drain_queue
      end
    end
  end

  describe '#execute' do
    context 'default_aggregate action' do
      let(:action) { 'default_aggregate' }

      it 'should deserialize the json, import into the cache' do
        fixture = PuppetLanguageServer::Sidecar::Protocol::AggregateMetadata.new
        fixture.append!(random_sidecar_puppet_class)
        fixture.append!(random_sidecar_puppet_function)
        fixture.append!(random_sidecar_puppet_type)
        sidecar_response = [fixture.to_json, 'stderr', SuccessStatus.new]

        expect(subject).to receive(:run_sidecar).and_return(sidecar_response)

        subject.execute(action, [], false, connection_id)
        expect(cache.object_by_name(:class, fixture.classes[0].key)).to_not be_nil
        expect(cache.object_by_name(:function, fixture.functions[0].key)).to_not be_nil
        expect(cache.object_by_name(:type, fixture.types[0].key)).to_not be_nil
      end
    end

    context 'default_classes action' do
      let(:action) { 'default_classes' }

      it 'should deserialize the json, import into the cache' do
        fixture = PuppetLanguageServer::Sidecar::Protocol::PuppetClassList.new
        fixture << random_sidecar_puppet_class
        sidecar_response = [fixture.to_json, 'stderr', SuccessStatus.new]

        expect(subject).to receive(:run_sidecar).and_return(sidecar_response)

        subject.execute(action, [], false, connection_id)
        expect(cache.object_by_name(:class, fixture[0].key)).to_not be nil
      end
    end

    context 'default_functions action' do
      let(:action) { 'default_functions' }

      it 'should deserialize the json, import into the cache' do
        fixture = PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionList.new
        fixture << random_sidecar_puppet_function
        sidecar_response = [fixture.to_json, 'stderr', SuccessStatus.new]

        expect(subject).to receive(:run_sidecar).and_return(sidecar_response)

        subject.execute(action, [], false, connection_id)
        expect(cache.object_by_name(:function, fixture[0].key)).to_not be nil
      end
    end

    context 'default_types action' do
      let(:action) { 'default_types' }

      it 'should deserialize the json, import into the cache' do
        fixture = PuppetLanguageServer::Sidecar::Protocol::PuppetTypeList.new
        fixture << random_sidecar_puppet_type
        sidecar_response = [fixture.to_json, 'stderr', SuccessStatus.new]

        expect(subject).to receive(:run_sidecar).and_return(sidecar_response)

        subject.execute(action, [], false, connection_id)
        expect(cache.object_by_name(:type, fixture[0].key)).to_not be nil
      end
    end
  end
end
