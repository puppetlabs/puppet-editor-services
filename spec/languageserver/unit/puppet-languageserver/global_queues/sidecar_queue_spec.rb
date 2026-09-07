require 'spec_helper'
require 'puppet-languageserver/session_state/document_store'

describe 'PuppetLanguageServer::GlobalQueues::SidecarQueueJob' do
  let(:action) { 'action' }
  let(:additional_args) { [] }
  let(:handle_errors) { false }
  let(:connection_id) { 'id1234' }

  let(:subject) { PuppetLanguageServer::GlobalQueues::SidecarQueueJob.new(action, additional_args, handle_errors, connection_id) }

  it 'is a SingleInstanceQueueJob' do
    expect(subject).is_a?(PuppetLanguageServer::GlobalQueues::SingleInstanceQueueJob)
  end

  it 'uses the action and connection_id for the key' do
    expect(subject.key).to eq("#{action}-#{connection_id}")
  end
end

describe 'PuppetLanguageServer::GlobalQueues::SidecarQueue' do
  let(:subject) { PuppetLanguageServer::GlobalQueues::SidecarQueue.new }

  it 'is a SingleInstanceQueue' do
    expect(subject).is_a?(PuppetLanguageServer::GlobalQueues::SingleInstanceQueue)
  end

  it 'has a job_class of SidecarQueueJob' do
    expect(subject.job_class).is_a?(PuppetLanguageServer::GlobalQueues::SingleInstanceQueueJob)
  end

  describe '#execute' do
    let(:mock_connection) { Object.new }
    let(:connection_id) { 'mock_conn_id' }
    let(:cache) { PuppetLanguageServer::SessionState::ObjectCache.new }
    let(:session_state) { PuppetLanguageServer::ClientSessionState.new(nil, :object_cache => cache, :connection_id => connection_id) }

    before(:each) do
      # Mock a connection and session state
      allow(subject).to receive(:connection_from_connection_id).with(connection_id).and_return(mock_connection)
      allow(subject).to receive(:sidecar_args_from_connection).with(mock_connection).and_return([])
      allow(subject).to receive(:session_state_from_connection).with(mock_connection).and_return(session_state)
    end

    class SuccessStatus
      def exitstatus
        0
      end
    end

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

    context 'default_datatypes action' do
      let(:action) { 'default_datatypes' }

      it 'should deserialize the json, import into the cache' do
        fixture = PuppetLanguageServer::Sidecar::Protocol::PuppetDataTypeList.new
        fixture << random_sidecar_puppet_datatype
        sidecar_response = [fixture.to_json, 'stderr', SuccessStatus.new]

        expect(subject).to receive(:run_sidecar).and_return(sidecar_response)

        subject.execute(action, [], false, connection_id)
        expect(cache.object_by_name(:datatype, fixture[0].key)).to_not be nil
      end
    end

    context 'facts action' do
      let(:action) { 'facts' }

      it 'should deserialize the json, import into the cache' do
        fixture = PuppetLanguageServer::Sidecar::Protocol::FactList.new
        fixture << random_sidecar_fact
        sidecar_response = [fixture.to_json, 'stderr', SuccessStatus.new]

        expect(subject).to receive(:run_sidecar).and_return(sidecar_response)

        subject.execute(action, [], false, connection_id)
        expect(cache.object_by_name(:fact, fixture[0].key)).to_not be nil
      end
    end

    context 'node_graph action' do
      let(:action) { 'node_graph' }

      it 'returns a PuppetNodeGraph object' do
        fixture = PuppetLanguageServer::Sidecar::Protocol::PuppetNodeGraph.new
        fixture.vertices = []
        fixture.edges = []
        fixture.error_content = ''
        sidecar_response = [fixture.to_json, 'stderr', SuccessStatus.new]

        expect(subject).to receive(:run_sidecar).and_return(sidecar_response)

        result = subject.execute(action, [], false, connection_id)
        expect(result).to be_a(PuppetLanguageServer::Sidecar::Protocol::PuppetNodeGraph)
      end
    end

    context 'resource_list action' do
      let(:action) { 'resource_list' }

      it 'returns a ResourceList object' do
        fixture = PuppetLanguageServer::Sidecar::Protocol::ResourceList.new
        fixture << random_sidecar_resource
        sidecar_response = [fixture.to_json, 'stderr', SuccessStatus.new]

        expect(subject).to receive(:run_sidecar).and_return(sidecar_response)

        result = subject.execute(action, [], false, connection_id)
        expect(result).to be_a(PuppetLanguageServer::Sidecar::Protocol::ResourceList)
      end
    end

    context 'workspace_aggregate action' do
      let(:action) { 'workspace_aggregate' }

      it 'should deserialize the json, import into the cache under workspace origin' do
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
        expect(cache.section_in_origin_exist?(:class, :workspace)).to be(true)
      end
    end

    context 'workspace_classes action' do
      let(:action) { 'workspace_classes' }

      it 'should deserialize the json, import into the cache under workspace origin' do
        fixture = PuppetLanguageServer::Sidecar::Protocol::PuppetClassList.new
        fixture << random_sidecar_puppet_class
        sidecar_response = [fixture.to_json, 'stderr', SuccessStatus.new]

        expect(subject).to receive(:run_sidecar).and_return(sidecar_response)

        subject.execute(action, [], false, connection_id)
        expect(cache.object_by_name(:class, fixture[0].key)).to_not be_nil
        expect(cache.section_in_origin_exist?(:class, :workspace)).to be(true)
      end
    end

    context 'workspace_datatypes action' do
      let(:action) { 'workspace_datatypes' }

      it 'should deserialize the json, import into the cache under workspace origin' do
        fixture = PuppetLanguageServer::Sidecar::Protocol::PuppetDataTypeList.new
        fixture << random_sidecar_puppet_datatype
        sidecar_response = [fixture.to_json, 'stderr', SuccessStatus.new]

        expect(subject).to receive(:run_sidecar).and_return(sidecar_response)

        subject.execute(action, [], false, connection_id)
        expect(cache.object_by_name(:datatype, fixture[0].key)).to_not be_nil
        expect(cache.section_in_origin_exist?(:datatype, :workspace)).to be(true)
      end
    end

    context 'workspace_functions action' do
      let(:action) { 'workspace_functions' }

      it 'should deserialize the json, import into the cache under workspace origin' do
        fixture = PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionList.new
        fixture << random_sidecar_puppet_function
        sidecar_response = [fixture.to_json, 'stderr', SuccessStatus.new]

        expect(subject).to receive(:run_sidecar).and_return(sidecar_response)

        subject.execute(action, [], false, connection_id)
        expect(cache.object_by_name(:function, fixture[0].key)).to_not be_nil
        expect(cache.section_in_origin_exist?(:function, :workspace)).to be(true)
      end
    end

    context 'workspace_types action' do
      let(:action) { 'workspace_types' }

      it 'should deserialize the json, import into the cache under workspace origin' do
        fixture = PuppetLanguageServer::Sidecar::Protocol::PuppetTypeList.new
        fixture << random_sidecar_puppet_type
        sidecar_response = [fixture.to_json, 'stderr', SuccessStatus.new]

        expect(subject).to receive(:run_sidecar).and_return(sidecar_response)

        subject.execute(action, [], false, connection_id)
        expect(cache.object_by_name(:type, fixture[0].key)).to_not be_nil
        expect(cache.section_in_origin_exist?(:type, :workspace)).to be(true)
      end
    end

    context 'unknown action' do
      let(:action) { 'unknown_action' }

      it 'logs an error and returns true' do
        sidecar_response = ['{}', 'stderr', SuccessStatus.new]
        expect(subject).to receive(:run_sidecar).and_return(sidecar_response)
        allow(PuppetLanguageServer).to receive(:log_message)
        expect(PuppetLanguageServer).to receive(:log_message).with(:error, /Unknown action/)

        result = subject.execute(action, [], false, connection_id)
        expect(result).to be(true)
      end
    end

    context 'when an error is raised and handle_errors is true' do
      let(:action) { 'default_classes' }

      it 'logs the error and returns nil instead of raising' do
        allow(subject).to receive(:run_sidecar).and_raise(StandardError, 'mock error')
        allow(PuppetLanguageServer).to receive(:log_message)
        expect(PuppetLanguageServer).to receive(:log_message).with(:error, /mock error/)

        result = subject.execute(action, [], true, connection_id)
        expect(result).to be_nil
      end
    end
  end
end
