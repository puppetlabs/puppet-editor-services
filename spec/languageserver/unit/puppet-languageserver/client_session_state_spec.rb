require 'spec_helper'

describe 'PuppetLanguageServer::ClientSessionState' do
  let(:async) { false } # Always load synchoronously for rspec testing
  let(:subject) { PuppetLanguageServer::ClientSessionState.new(nil, :connection_id => '123') }

  describe '#load_static_data!' do
    def contains_bolt_objects?(cache)
      !cache.object_by_name(:datatype, 'Boltlib::PlanResult').nil? &&
      !cache.object_by_name(:datatype, 'Boltlib::TargetSpec').nil?
    end

    it 'loads without error' do
      subject.load_static_data!(async)

      expect(contains_bolt_objects?(subject.object_cache)).to be(true)
    end
  end

  describe '#static_data_loaded?' do
    it 'sets static_data_loaded? to true after loading' do
      expect(subject.static_data_loaded?).to be(false)
      subject.load_static_data!(async)
      expect(subject.static_data_loaded?).to be(true)
    end
  end

  describe '#default_classes_loaded?' do
    it 'returns false initially' do
      expect(subject.default_classes_loaded?).to be(false)
    end

    it 'returns true once default classes are in the cache' do
      subject.object_cache.import_sidecar_list!([random_sidecar_puppet_class], :class, :default)
      expect(subject.default_classes_loaded?).to be(true)
    end
  end

  describe '#default_datatypes_loaded?' do
    it 'returns false initially' do
      expect(subject.default_datatypes_loaded?).to be(false)
    end

    it 'returns true once default datatypes are in the cache' do
      subject.object_cache.import_sidecar_list!([random_sidecar_puppet_datatype], :datatype, :default)
      expect(subject.default_datatypes_loaded?).to be(true)
    end
  end

  describe '#default_functions_loaded?' do
    it 'returns false initially' do
      expect(subject.default_functions_loaded?).to be(false)
    end

    it 'returns true once default functions are in the cache' do
      subject.object_cache.import_sidecar_list!([random_sidecar_puppet_function], :function, :default)
      expect(subject.default_functions_loaded?).to be(true)
    end
  end

  describe '#default_types_loaded?' do
    it 'returns false initially' do
      expect(subject.default_types_loaded?).to be(false)
    end

    it 'returns true once default types are in the cache' do
      subject.object_cache.import_sidecar_list!([random_sidecar_puppet_type], :type, :default)
      expect(subject.default_types_loaded?).to be(true)
    end
  end

  describe '#facts_loaded?' do
    it 'returns false initially' do
      expect(subject.facts_loaded?).to be(false)
    end

    it 'returns true once facts are in the cache' do
      subject.object_cache.import_sidecar_list!([random_sidecar_fact], :fact, :default)
      expect(subject.facts_loaded?).to be(true)
    end
  end

  describe '#load_default_data!' do
    let(:mock_queue) { double('sidecar_queue') }

    before do
      allow(PuppetLanguageServer::GlobalQueues).to receive(:sidecar_queue).and_return(mock_queue)
      allow(PuppetLanguageServer).to receive(:log_message)
    end

    it 'executes default_aggregate synchronously' do
      expect(mock_queue).to receive(:execute).with('default_aggregate', [], false, '123')
      expect(mock_queue).to receive(:execute).with('facts', [], false, '123')
      subject.load_default_data!(false)
    end

    it 'enqueues default_aggregate asynchronously' do
      expect(mock_queue).to receive(:enqueue).with('default_aggregate', [], false, '123')
      expect(mock_queue).to receive(:enqueue).with('facts', [], false, '123')
      subject.load_default_data!(true)
    end

    it 'returns true' do
      allow(mock_queue).to receive(:execute)
      expect(subject.load_default_data!(false)).to be(true)
    end
  end

  describe '#load_workspace_data!' do
    let(:mock_queue) { double('sidecar_queue') }

    before do
      allow(PuppetLanguageServer::GlobalQueues).to receive(:sidecar_queue).and_return(mock_queue)
      allow(PuppetLanguageServer).to receive(:log_message)
    end

    context 'when store_root_path is nil' do
      it 'returns true without enqueuing' do
        expect(mock_queue).not_to receive(:execute)
        expect(mock_queue).not_to receive(:enqueue)
        expect(subject.load_workspace_data!(false)).to be(true)
      end
    end

    context 'when store_root_path is set' do
      before { allow(subject.documents).to receive(:store_root_path).and_return('/some/path') }

      it 'executes workspace_aggregate synchronously' do
        expect(mock_queue).to receive(:execute).with('workspace_aggregate', ['--local-workspace', '/some/path'], false, '123')
        subject.load_workspace_data!(false)
      end

      it 'enqueues workspace_aggregate asynchronously' do
        expect(mock_queue).to receive(:enqueue).with('workspace_aggregate', ['--local-workspace', '/some/path'], false, '123')
        subject.load_workspace_data!(true)
      end

      it 'returns true' do
        allow(mock_queue).to receive(:execute)
        expect(subject.load_workspace_data!(false)).to be(true)
      end
    end
  end

  describe '#purge_workspace_data!' do
    it 'removes workspace origin from the object cache' do
      subject.object_cache.import_sidecar_list!([random_sidecar_puppet_class], :class, :workspace)
      expect(subject.object_cache.section_in_origin_exist?(:class, :workspace)).to be(true)
      subject.purge_workspace_data!
      expect(subject.object_cache.section_in_origin_exist?(:class, :workspace)).to be(false)
    end
  end
end
