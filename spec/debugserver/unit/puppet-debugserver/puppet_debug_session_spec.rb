require 'spec_debug_helper'

describe 'PuppetDebugServer::PuppetDebugSession' do
  let(:subject) { PuppetDebugServer::PuppetDebugSession.new }

  before(:each) do
    allow(PuppetDebugServer).to receive(:log_message)
  end

  describe '#initialize' do
    it 'creates a flow_control object' do
      expect(subject.flow_control).to be_a(PuppetDebugServer::DebugSession::FlowControl)
    end

    it 'creates a hook_manager' do
      expect(subject.hook_manager).to be_a(PuppetDebugServer::Hooks)
    end

    it 'creates breakpoints' do
      expect(subject.breakpoints).to be_a(PuppetDebugServer::DebugSession::BreakPoints)
    end

    it 'creates puppet_session_state' do
      expect(subject.puppet_session_state).to be_a(PuppetDebugServer::DebugSession::PuppetSessionState)
    end
  end

  describe '#execute_hook' do
    it 'delegates to hook_manager.exec_hook' do
      expect(subject.hook_manager).to receive(:exec_hook).with(:my_event, [1, 2])
      subject.execute_hook(:my_event, [1, 2])
    end
  end

  describe '#initialize_session' do
    it 'sets puppet_thread_id to the current thread object_id' do
      subject.initialize_session
      expect(subject.puppet_thread_id).to eq(Thread.current.object_id.to_i)
    end
  end

  describe '#send_output_event' do
    context 'when message_handler is nil' do
      it 'does nothing' do
        expect { subject.send_output_event('output' => 'hello') }.not_to raise_error
      end
    end

    context 'when message_handler is set' do
      let(:mock_handler) { double('message_handler') }

      before(:each) do
        subject.setup(mock_handler, {})
      end

      it 'delegates to message_handler.send_output_event' do
        expect(mock_handler).to receive(:send_output_event)
        subject.send_output_event('output' => 'hello')
      end
    end
  end

  describe '#send_stopped_event' do
    context 'when message_handler is nil' do
      it 'does nothing' do
        expect { subject.send_stopped_event('breakpoint') }.not_to raise_error
      end
    end

    context 'when message_handler is set' do
      let(:mock_handler) { double('message_handler') }

      before(:each) { subject.setup(mock_handler, {}) }

      it 'delegates to message_handler.send_stopped_event' do
        expect(mock_handler).to receive(:send_stopped_event).with('breakpoint', {})
        subject.send_stopped_event('breakpoint')
      end
    end
  end

  describe '#send_thread_event' do
    context 'when message_handler is nil' do
      it 'does nothing' do
        expect { subject.send_thread_event('started', 1) }.not_to raise_error
      end
    end

    context 'when message_handler is set' do
      let(:mock_handler) { double('message_handler') }

      before(:each) { subject.setup(mock_handler, {}) }

      it 'delegates to message_handler.send_thread_event' do
        expect(mock_handler).to receive(:send_thread_event).with('started', 1)
        subject.send_thread_event('started', 1)
      end
    end
  end

  describe '#send_termination_event' do
    context 'when message_handler is nil' do
      it 'does nothing' do
        expect { subject.send_termination_event }.not_to raise_error
      end
    end

    context 'when message_handler is set' do
      let(:mock_handler) { double('message_handler') }

      before(:each) { subject.setup(mock_handler, {}) }

      it 'delegates to message_handler.send_termination_event' do
        expect(mock_handler).to receive(:send_termination_event)
        subject.send_termination_event
      end
    end
  end

  describe '#send_exited_event' do
    context 'when message_handler is nil' do
      it 'does nothing' do
        expect { subject.send_exited_event(0) }.not_to raise_error
      end
    end

    context 'when message_handler is set' do
      let(:mock_handler) { double('message_handler') }

      before(:each) { subject.setup(mock_handler, {}) }

      it 'delegates to message_handler.send_exited_event' do
        expect(mock_handler).to receive(:send_exited_event).with(0)
        subject.send_exited_event(0)
      end
    end
  end

  describe '#setup' do
    let(:mock_handler) { double('message_handler') }

    it 'stores the message handler and asserts session_setup flag' do
      subject.setup(mock_handler, {})
      expect(subject.flow_control.flag?(:session_setup)).to be true
    end
  end

  describe '#close' do
    it 'calls send_termination_event' do
      expect(subject).to receive(:send_termination_event)
      subject.close
    end
  end

  describe '#generate_stackframe_list' do
    it 'returns an empty array when saved state has nothing' do
      result = subject.generate_stackframe_list
      expect(result).to eq([])
    end

    it 'generates a stack frame from puppet_stacktrace' do
      subject.puppet_session_state.saved.update!(puppet_stacktrace: [['/path/to/manifest.pp', 10]])
      result = subject.generate_stackframe_list
      expect(result.length).to eq(1)
      expect(result.first.line).to eq(10)
    end

    it 'generates a stack frame from exception with file and line' do
      err = double('exception', class: RuntimeError, file: '/my/file.pp', line: 5, pos: 2)
      allow(err).to receive(:class).and_return(RuntimeError)
      subject.puppet_session_state.saved.update!(session_exception: err)
      result = subject.generate_stackframe_list
      expect(result.length).to eq(1)
      expect(result.first.line).to eq(5)
    end

    it 'generates a stack frame from exception without file/line' do
      err = double('exception', class: RuntimeError, file: nil, line: nil)
      allow(err).to receive(:class).and_return(RuntimeError)
      subject.puppet_session_state.saved.update!(session_exception: err)
      result = subject.generate_stackframe_list
      expect(result.length).to eq(1)
      expect(result.first.line).to eq(0)
    end
  end

  describe '#generate_scopes_list' do
    it 'returns empty array for non-zero frame_id' do
      expect(subject.generate_scopes_list(1)).to eq([])
      expect(subject.generate_scopes_list(5)).to eq([])
    end

    it 'returns empty array for frame 0 when scope and compiler are nil' do
      result = subject.generate_scopes_list(0)
      expect(result).to eq([])
    end
  end

  describe '#get_puppet_class_name' do
    it 'returns the class name via _pcore_type if available' do
      obj = double('pops_obj')
      pcore = double('pcore', simple_name: 'MyClass')
      allow(obj).to receive(:respond_to?).with(:_pcore_type).and_return(true)
      allow(obj).to receive(:_pcore_type).and_return(pcore)
      expect(subject.get_puppet_class_name(obj)).to eq('MyClass')
    end

    it 'falls back to splitting class name on ::' do
      obj = double('pops_obj')
      allow(obj).to receive(:respond_to?).with(:_pcore_type).and_return(false)
      allow(obj).to receive(:class).and_return(Puppet::Pops::Model::CallNamedFunctionExpression)
      expect(subject.get_puppet_class_name(obj)).to eq('CallNamedFunctionExpression')
    end
  end
end

describe 'PuppetDebugServer::SourcePosition' do
  let(:subject) { PuppetDebugServer::SourcePosition.new }

  it 'has accessible file, line, offset, and length attributes' do
    subject.file   = '/my/file.pp'
    subject.line   = 10
    subject.offset = 5
    subject.length = 3
    expect(subject.file).to eq('/my/file.pp')
    expect(subject.line).to eq(10)
    expect(subject.offset).to eq(5)
    expect(subject.length).to eq(3)
  end
end
