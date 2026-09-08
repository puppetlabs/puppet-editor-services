require 'spec_helper'

describe 'PuppetLanguageServer::PuppetHelper' do
  let(:session_state) { PuppetLanguageServer::ClientSessionState.new(nil, connection_id: 'mock') }
  let(:subject) { PuppetLanguageServer::PuppetHelper }

  before(:each) do
    populate_cache(session_state.object_cache)
    allow(PuppetLanguageServer).to receive(:log_message)
  end

  describe '#get_type' do
    it 'returns nil for unknown type' do
      expect(subject.get_type(session_state, 'nonexistent_xyz')).to be_nil
    end

    it 'returns a type object for a known type' do
      result = subject.get_type(session_state, 'user')
      expect(result).not_to be_nil
    end
  end

  describe '#type_names' do
    it 'returns an array of type name strings' do
      result = subject.type_names(session_state)
      expect(result).to be_an(Array)
      expect(result).to include('user')
    end
  end

  describe '#function' do
    it 'returns a function object for a known function' do
      result = subject.function(session_state, 'notice')
      expect(result).not_to be_nil
    end

    it 'returns nil for unknown function' do
      expect(subject.function(session_state, 'nonexistent_xyz')).to be_nil
    end

    it 'excludes bolt origins when tasks_mode is false' do
      result = subject.function(session_state, 'notice', false)
      expect(result).not_to be_nil
    end

    it 'includes bolt origins when tasks_mode is true' do
      result = subject.function(session_state, 'notice', true)
      expect(result).not_to be_nil
    end
  end

  describe '#function_names' do
    it 'returns an array of function name strings' do
      result = subject.function_names(session_state)
      expect(result).to be_an(Array)
      expect(result).to include('notice')
    end

    it 'returns functions for tasks_mode' do
      result = subject.function_names(session_state, true)
      expect(result).to be_an(Array)
    end
  end

  describe '#get_class' do
    it 'returns nil for unknown class' do
      expect(subject.get_class(session_state, 'nonexistent_class_xyz')).to be_nil
    end
  end

  describe '#class_names' do
    it 'returns an array of class names' do
      result = subject.class_names(session_state)
      expect(result).to be_an(Array)
    end
  end

  describe '#datatype' do
    it 'returns a datatype for a known type' do
      result = subject.datatype(session_state, 'String')
      # May or may not exist in fixture, but should not raise
      expect { result }.not_to raise_error
    end

    it 'returns nil for unknown datatype' do
      expect(subject.datatype(session_state, 'NonExistentType_xyz')).to be_nil
    end

    it 'supports tasks_mode parameter' do
      expect { subject.datatype(session_state, 'String', true) }.not_to raise_error
    end
  end

  describe '#sidecar_queue' do
    it 'delegates to GlobalQueues.sidecar_queue' do
      mock_queue = double('sidecar_queue')
      allow(PuppetLanguageServer::GlobalQueues).to receive(:sidecar_queue).and_return(mock_queue)
      expect(subject.sidecar_queue).to eq(mock_queue)
    end
  end

  describe '#with_temporary_file (private)' do
    it 'yields the file path as a string' do
      yielded_path = nil
      subject.send(:with_temporary_file, 'test content') { |path| yielded_path = path }
      expect(yielded_path).to be_a(String)
    end

    it 'cleans up the temp file after the block' do
      yielded_path = nil
      subject.send(:with_temporary_file, 'test content') { |path| yielded_path = path }
      expect(File.exist?(yielded_path)).to be false
    end
  end

  describe '#get_node_graph' do
    let(:mock_queue) { double('sidecar_queue') }

    before do
      allow(PuppetLanguageServer::GlobalQueues).to receive(:sidecar_queue).and_return(mock_queue)
      allow(mock_queue).to receive(:execute)
    end

    it 'calls sidecar_queue.execute with node_graph action' do
      expect(mock_queue).to receive(:execute).with('node_graph', anything, false, 'mock')
      subject.get_node_graph(session_state, 'content', nil)
    end

    it 'passes local_workspace when provided' do
      expect(mock_queue).to receive(:execute) do |action, args, _async, _conn_id|
        expect(action).to eq('node_graph')
        expect(args.any? { |a| a.include?('/tmp') }).to be true
      end
      subject.get_node_graph(session_state, 'content', '/tmp')
    end
  end

  describe '#get_puppet_resource' do
    let(:mock_queue) { double('sidecar_queue') }

    before do
      allow(PuppetLanguageServer::GlobalQueues).to receive(:sidecar_queue).and_return(mock_queue)
      allow(mock_queue).to receive(:execute)
    end

    it 'calls sidecar_queue.execute with resource_list action' do
      expect(mock_queue).to receive(:execute).with('resource_list', anything, false, 'mock')
      subject.get_puppet_resource(session_state, 'user', nil, nil)
    end

    it 'includes the title in action params when provided' do
      expect(mock_queue).to receive(:execute) do |action, args, _async, _conn_id|
        expect(action).to eq('resource_list')
        expect(args.first).to include('Bob')
      end
      subject.get_puppet_resource(session_state, 'user', 'Bob', nil)
    end
  end
end
