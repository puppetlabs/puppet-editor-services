require 'spec_helper'

class SuccessStatus
  def exitstatus
    0
  end
end

describe 'sidecar_queue' do
  let(:cache) { PuppetLanguageServer::PuppetHelper::Cache.new }
  let(:subject) {
    subject = PuppetLanguageServer::SidecarQueue.new
    subject.cache = cache
    subject
  }

  describe '#enqueue' do
    let(:action1) { 'default_classes' }
    let(:action2) { 'default_types' }
    let(:additional_args1) { [] }
    let(:additional_args2) { [] }

    before(:each) do
      allow(subject).to receive(:execute_sync).and_raise("PuppetLanguageServer::SidecarQueue.execute_sync mock should not be called")
    end

    context 'for a single item in the queue' do
      before(:each) do
        expect(subject).to receive(:execute_sync).with(action1, additional_args1).and_return(true)
      end

      it 'should call the synchronous method' do
        subject.enqueue(action1, additional_args1)
        subject.drain_queue
      end
    end

    context 'for multiple items in the queue' do
      it 'should process all unique actions' do
        expect(subject).to receive(:execute_sync).with(action1, additional_args1).and_return(true)
        expect(subject).to receive(:execute_sync).with(action2, additional_args2).and_return(true)

        subject.enqueue(action1, additional_args1)
        subject.enqueue(action2, additional_args2)
        subject.drain_queue
      end

      it 'should ignore duplicate actions' do
        expect(subject).to receive(:execute_sync).with(action1, additional_args1).and_return(true)
        expect(subject).to receive(:execute_sync).with(action2, additional_args2).and_return(true)

        # Populate the queue with one of each action
        subject.reset_queue([
          { action: action1, additional_args: additional_args1},
          { action: action2, additional_args: additional_args2},
        ])

        subject.enqueue(action2, additional_args2)
        subject.drain_queue
      end
    end
  end

  describe '#execute_sync' do
    context 'default_aggregate action' do
      let(:action) { 'default_aggregate' }

      it 'should deserialize the json, import into the cache and assert default classes are loaded' do
        fixture = PuppetLanguageServer::Sidecar::Protocol::AggregateMetadata.new
        fixture.append!(random_sidecar_puppet_class)
        fixture.append!(random_sidecar_puppet_function)
        fixture.append!(random_sidecar_puppet_type)
        sidecar_response = [fixture.to_json, 'stderr', SuccessStatus.new]

        expect(subject).to receive(:run_sidecar).and_return(sidecar_response)
        expect(PuppetLanguageServer::PuppetHelper).to receive(:assert_default_classes_loaded)
        expect(PuppetLanguageServer::PuppetHelper).to receive(:assert_default_functions_loaded)
        expect(PuppetLanguageServer::PuppetHelper).to receive(:assert_default_types_loaded)

        subject.execute_sync(action, [])
        expect(cache.object_by_name(:class, fixture.classes[0].key)).to_not be_nil
        expect(cache.object_by_name(:function, fixture.functions[0].key)).to_not be_nil
        expect(cache.object_by_name(:type, fixture.types[0].key)).to_not be_nil
      end
    end

    context 'default_classes action' do
      let(:action) { 'default_classes' }

      it 'should deserialize the json, import into the cache and assert default classes are loaded' do
        fixture = PuppetLanguageServer::Sidecar::Protocol::PuppetClassList.new
        fixture << random_sidecar_puppet_class
        sidecar_response = [fixture.to_json, 'stderr', SuccessStatus.new]

        expect(subject).to receive(:run_sidecar).and_return(sidecar_response)
        expect(PuppetLanguageServer::PuppetHelper).to receive(:assert_default_classes_loaded)

        subject.execute_sync(action, [])
        expect(cache.object_by_name(:class, fixture[0].key)).to_not be nil
      end
    end

    context 'default_functions action' do
      let(:action) { 'default_functions' }

      it 'should deserialize the json, import into the cache and assert default functions are loaded' do
        fixture = PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionList.new
        fixture << random_sidecar_puppet_function
        sidecar_response = [fixture.to_json, 'stderr', SuccessStatus.new]

        expect(subject).to receive(:run_sidecar).and_return(sidecar_response)
        expect(PuppetLanguageServer::PuppetHelper).to receive(:assert_default_functions_loaded)

        subject.execute_sync(action, [])
        expect(cache.object_by_name(:function, fixture[0].key)).to_not be nil
      end
    end

    context 'default_types action' do
      let(:action) { 'default_types' }

      it 'should deserialize the json, import into the cache and assert default types are loaded' do
        fixture = PuppetLanguageServer::Sidecar::Protocol::PuppetTypeList.new
        fixture << random_sidecar_puppet_type
        sidecar_response = [fixture.to_json, 'stderr', SuccessStatus.new]

        expect(subject).to receive(:run_sidecar).and_return(sidecar_response)
        expect(PuppetLanguageServer::PuppetHelper).to receive(:assert_default_types_loaded)

        subject.execute_sync(action, [])
        expect(cache.object_by_name(:type, fixture[0].key)).to_not be nil
      end
    end
  end
end
