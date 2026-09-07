require 'spec_debug_helper'
require 'tempfile'

describe 'PuppetDebugServer::DebugSession::BreakPoints' do
  let(:debug_session) { instance_double(PuppetDebugServer::PuppetDebugSession) }
  let(:subject) { PuppetDebugServer::DebugSession::BreakPoints.new(debug_session) }

  def make_set_breakpoints_args(file_path, lines)
    args = DSP::SetBreakpointsArguments.new
    args.source = DSP::Source.new
    args.source.path = file_path
    args.breakpoints = lines.map do |line|
      bp = DSP::SourceBreakpoint.new
      bp.line = line
      bp
    end
    args
  end

  def make_set_function_breakpoints_args(names)
    args = DSP::SetFunctionBreakpointsArguments.new
    args.breakpoints = names.map do |name|
      fb = DSP::FunctionBreakpoint.new
      fb.name = name
      fb
    end
    args
  end

  before(:each) do
    allow(PuppetDebugServer).to receive(:log_message)
  end

  describe '#process_set_breakpoints_request!' do
    context 'when the source file does not exist' do
      it 'logs a debug message and returns unverified breakpoints' do
        args = make_set_breakpoints_args('/no/such/file.pp', [1])
        expect(PuppetDebugServer).to receive(:log_message).with(:debug, /non-existant file/)
        result = subject.process_set_breakpoints_request!(args)
        expect(result.length).to eq(1)
        expect(result.first.verified).to be false
      end
    end

    context 'when the source file exists' do
      let(:tmp_file) do
        f = Tempfile.new(['test', '.pp'])
        f.write("class foo {\n  # comment\n  notify { 'hello': }\n}\n")
        f.flush
        f
      end

      after(:each) { tmp_file.close; tmp_file.unlink }

      it 'verifies a breakpoint on a non-blank, non-comment line' do
        args = make_set_breakpoints_args(tmp_file.path, [3])
        result = subject.process_set_breakpoints_request!(args)
        expect(result.length).to eq(1)
        expect(result.first.verified).to be true
        expect(result.first.line).to eq(3)
      end

      it 'returns unverified breakpoint for a blank/comment-only line' do
        args = make_set_breakpoints_args(tmp_file.path, [2])
        result = subject.process_set_breakpoints_request!(args)
        expect(result.first.verified).to be false
        expect(result.first.message).to match(/blank/i)
      end

      it 'returns unverified breakpoint for a line beyond end of file' do
        args = make_set_breakpoints_args(tmp_file.path, [999])
        result = subject.process_set_breakpoints_request!(args)
        expect(result.first.verified).to be false
        expect(result.first.message).to match(/does not exist/i)
      end

      it 'updates the internal line breakpoints for the file' do
        args = make_set_breakpoints_args(tmp_file.path, [3])
        subject.process_set_breakpoints_request!(args)
        breakpoints = subject.line_breakpoints(tmp_file.path)
        expect(breakpoints).to include(3)
      end
    end
  end

  describe '#process_set_function_breakpoints_request!' do
    it 'returns verified breakpoints for all requested functions' do
      args = make_set_function_breakpoints_args(['my::func', 'other::func'])
      result = subject.process_set_function_breakpoints_request!(args)
      expect(result.length).to eq(2)
      result.each { |bp| expect(bp.verified).to be true }
    end
  end

  describe '#line_breakpoints' do
    it 'returns empty array when no breakpoints set for the file' do
      expect(subject.line_breakpoints('/no/such/file.pp')).to eq([])
    end
  end

  describe '#function_breakpoint_names' do
    it 'always includes debug::break' do
      expect(subject.function_breakpoint_names).to include('debug::break')
    end

    it 'includes custom function names when set' do
      args = make_set_function_breakpoints_args(['mymod::myfunc'])
      subject.process_set_function_breakpoints_request!(args)
      expect(subject.function_breakpoint_names).to include('mymod::myfunc', 'debug::break')
    end
  end
end
