require 'spec_debug_helper'

def class_in_catalog(catalog, klass)
  require 'puppet'

  # Use Puppet to generate the AST
  parser = Puppet::Pops::Parser::Parser.new
  result = parser.parse_string(catalog, 'debug_hook_handlers.pp')

  # Now that we have a parsed AST, find the object we're interested in
  if result.model.respond_to? :eAllContents
    result.model.eAllContents.each do |item|
      return item if item.is_a?(klass)
    end
  else
    path = []
    result.model._pcore_all_contents(path) do |item|
      return item if item.is_a?(klass)
    end
  end

  nil
end

describe 'PuppetDebugServer::PuppetDebugSession' do
  let(:subject) { PuppetDebugServer::PuppetDebugSession.new }

  before(:each) do
    allow(PuppetDebugServer).to receive(:log_message)
    allow(subject).to receive(:execute_hook)
    subject.puppet_session_state.actual.reset!
  end

  describe '#hook_before_pops_evaluate' do
    let(:subject_args) {
      # Expects [self, target, scope]
      [self, class_in_catalog(catalog_text, target_class), nil ]
    }

    context 'with a manifest which contains a function called testfunc()' do
      let(:catalog_text) { <<-EOT
        class classtest {
          testfunc()
        }
      EOT
      }
      let(:target_class) { Puppet::Pops::Model::CallNamedFunctionExpression }

      # Function Break Points
      it 'should not raise a function breakpoint hook when it is not configured as trigger name' do
        expect(subject).to receive(:execute_hook)
          .with(:hook_function_breakpoint, any_args)
          .exactly(0).times

        result = subject.hook_handlers.on_hook_before_pops_evaluate(subject_args)
      end

      it 'should raise a function breakpoint hook when it is configured as trigger name' do
        allow(subject.breakpoints).to receive(:function_breakpoint_names).and_return(['testfunc'])
        expect(subject).to receive(:execute_hook)
          .with(:hook_function_breakpoint, any_args)
          .exactly(1).times

        result = subject.hook_handlers.on_hook_before_pops_evaluate(subject_args)
      end

      # Line Break Points
      it 'should not raise a breakpoint hook when it is not configured as line breakpoint' do
        expect(subject).to receive(:execute_hook)
          .with(:hook_breakpoint, any_args)
          .exactly(0).times

        result = subject.hook_handlers.on_hook_before_pops_evaluate(subject_args)
      end

      it 'should raise a breakpoint hook when it is configured as line breakpoint' do
        allow(subject.breakpoints).to receive(:line_breakpoints).and_return([2])
        expect(subject).to receive(:execute_hook)
          .with(:hook_breakpoint, any_args)
          .exactly(1).times

        result = subject.hook_handlers.on_hook_before_pops_evaluate(subject_args)
      end
    end
  end

  describe '#on_hook_before_pops_evaluate with stepping modes' do
    let(:catalog_text) { <<-EOT
      class classtest {
        testfunc()
      }
    EOT
    }
    let(:target_class) { Puppet::Pops::Model::CallNamedFunctionExpression }
    let(:subject_args) {
      [self, class_in_catalog(catalog_text, target_class), nil]
    }

    context 'with stepin mode' do
      before { subject.flow_control.run_mode.step_in! }

      it 'fires a step breakpoint hook' do
        expect(subject).to receive(:execute_hook).with(:hook_step_breakpoint, anything)
        subject.hook_handlers.on_hook_before_pops_evaluate(subject_args)
      end
    end

    context 'with next mode and pops depth at or below threshold' do
      before { subject.flow_control.run_mode.next!(100) }

      it 'fires a step breakpoint hook when depth <= threshold' do
        expect(subject).to receive(:execute_hook).with(:hook_step_breakpoint, anything)
        subject.hook_handlers.on_hook_before_pops_evaluate(subject_args)
      end
    end

    context 'with stepout mode and pops depth below threshold' do
      before { subject.flow_control.run_mode.step_out!(100) }

      it 'fires a step breakpoint hook when depth < threshold' do
        expect(subject).to receive(:execute_hook).with(:hook_step_breakpoint, anything)
        subject.hook_handlers.on_hook_before_pops_evaluate(subject_args)
      end
    end
  end

  describe '#on_hook_after_pops_evaluate' do
    it 'decrements pops depth when not paused' do
      subject.puppet_session_state.actual.increment_pops_depth
      initial_depth = subject.puppet_session_state.actual.pops_depth_level
      subject.hook_handlers.on_hook_after_pops_evaluate([])
      expect(subject.puppet_session_state.actual.pops_depth_level).to eq(initial_depth - 1)
    end

    it 'does not decrement pops depth when session is paused' do
      subject.flow_control.assert_flag(:session_paused)
      subject.puppet_session_state.actual.increment_pops_depth
      initial_depth = subject.puppet_session_state.actual.pops_depth_level
      subject.hook_handlers.on_hook_after_pops_evaluate([])
      expect(subject.puppet_session_state.actual.pops_depth_level).to eq(initial_depth)
    end
  end

  describe '#on_hook_before_apply_exit' do
    before(:each) do
      allow(subject).to receive(:send_exited_event)
      allow(subject).to receive(:send_output_event)
      allow(subject).to receive(:close)
      allow(subject).to receive(:force_terminate)
      allow(subject.hook_handlers).to receive(:sleep)
    end

    it 'calls send_exited_event with the exit code' do
      expect(subject).to receive(:send_exited_event).with(0)
      subject.hook_handlers.on_hook_before_apply_exit([0])
    end

    it 'calls send_output_event with exit message' do
      expect(subject).to receive(:send_output_event).with(hash_including('category' => 'console'))
      subject.hook_handlers.on_hook_before_apply_exit([0])
    end

    it 'calls close on the session' do
      expect(subject).to receive(:close)
      subject.hook_handlers.on_hook_before_apply_exit([0])
    end

    it 'calls force_terminate after sleeping' do
      expect(subject).to receive(:force_terminate)
      subject.hook_handlers.on_hook_before_apply_exit([0])
    end

    it 'unasserts the puppet_started flag' do
      subject.flow_control.assert_flag(:puppet_started)
      subject.hook_handlers.on_hook_before_apply_exit([0])
      expect(subject.flow_control.flag?(:puppet_started)).to be false
    end
  end

  describe '#on_hook_before_compile' do
    let(:mock_compiler) { double('compiler') }

    it 'updates the compiler in session state' do
      subject.flow_control.assert_flag(:client_completed_configuration)
      expect(subject.puppet_session_state.actual).to receive(:update_compiler).with(mock_compiler)
      subject.hook_handlers.on_hook_before_compile([mock_compiler])
    end

    it 'returns immediately when client_completed_configuration is set' do
      subject.flow_control.assert_flag(:client_completed_configuration)
      expect(subject.hook_handlers).not_to receive(:sleep)
      subject.hook_handlers.on_hook_before_compile([mock_compiler])
    end
  end

  describe '#on_hook_log_message' do
    let(:mock_msg) do
      msg = double('puppet_log_message')
      allow(msg).to receive(:respond_to?).with(:multiline).and_return(false)
      allow(msg).to receive(:to_s).and_return('test message')
      allow(msg).to receive(:source).and_return('Puppet')
      allow(msg).to receive(:level).and_return(:notice)
      msg
    end

    it 'sends an output event' do
      expect(subject).to receive(:send_output_event).with(hash_including('output'))
      subject.hook_handlers.on_hook_log_message([mock_msg])
    end

    it 'sends to stdout for notice level' do
      expect(subject).to receive(:send_output_event).with(hash_including('category' => 'stdout'))
      subject.hook_handlers.on_hook_log_message([mock_msg])
    end

    it 'sends to stderr for error level' do
      allow(mock_msg).to receive(:level).and_return(:err)
      expect(subject).to receive(:send_output_event).with(hash_including('category' => 'stderr'))
      subject.hook_handlers.on_hook_log_message([mock_msg])
    end

    it 'skips logging when suppress_log_messages flag is set' do
      subject.flow_control.assert_flag(:suppress_log_messages)
      expect(subject).not_to receive(:send_output_event)
      subject.hook_handlers.on_hook_log_message([mock_msg])
    end

    it 'uses multiline method when available' do
      allow(mock_msg).to receive(:respond_to?).with(:multiline).and_return(true)
      allow(mock_msg).to receive(:multiline).and_return('multiline output')
      expect(subject).to receive(:send_output_event).with(hash_including('output' => /multiline output/))
      subject.hook_handlers.on_hook_log_message([mock_msg])
    end

    it 'prepends source when source is not Puppet' do
      allow(mock_msg).to receive(:source).and_return('MyModule')
      expect(subject).to receive(:send_output_event).with(hash_including('output' => /MyModule/))
      subject.hook_handlers.on_hook_log_message([mock_msg])
    end

    it 'sends to stdout for info level' do
      allow(mock_msg).to receive(:level).and_return(:info)
      expect(subject).to receive(:send_output_event).with(hash_including('category' => 'stdout'))
      subject.hook_handlers.on_hook_log_message([mock_msg])
    end

    it 'sends to stdout for debug level' do
      allow(mock_msg).to receive(:level).and_return(:debug)
      expect(subject).to receive(:send_output_event).with(hash_including('category' => 'stdout'))
      subject.hook_handlers.on_hook_log_message([mock_msg])
    end
  end

  describe '#on_hook_exception' do
    it 'returns early when session is paused' do
      subject.flow_control.assert_flag(:session_paused)
      expect(subject.flow_control).not_to receive(:raise_stopped_event_and_wait)
      subject.hook_handlers.on_hook_exception([double('error')])
    end

    it 'calls raise_stopped_event_and_wait when not paused' do
      error = double('puppet_error')
      allow(error).to receive(:basic_message).and_return('error message')
      allow(Puppet::Pops::PuppetStack).to receive(:stacktrace_from_backtrace).and_return([])
      expect(subject.flow_control).to receive(:raise_stopped_event_and_wait).with(
        'exception', 'Compilation Exception', 'error message', anything
      )
      subject.hook_handlers.on_hook_exception([error])
    end
  end

  describe '#on_hook_breakpoint' do
    it 'returns early when session is paused' do
      subject.flow_control.assert_flag(:session_paused)
      expect(subject.flow_control).not_to receive(:raise_stopped_event_and_wait)
      subject.hook_handlers.on_hook_breakpoint(['breakpoint display', 'description'])
    end
  end

  describe '#on_hook_function_breakpoint' do
    it 'returns early when session is paused' do
      subject.flow_control.assert_flag(:session_paused)
      expect(subject.flow_control).not_to receive(:raise_stopped_event_and_wait)
      subject.hook_handlers.on_hook_function_breakpoint(['function display', 'description'])
    end
  end

  describe '#on_hook_step_breakpoint' do
    it 'returns early when session is paused' do
      subject.flow_control.assert_flag(:session_paused)
      expect(subject.flow_control).not_to receive(:raise_stopped_event_and_wait)
      subject.hook_handlers.on_hook_step_breakpoint(['step display', 'description'])
    end
  end
end
