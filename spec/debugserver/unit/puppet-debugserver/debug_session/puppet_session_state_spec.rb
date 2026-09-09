require 'spec_debug_helper'

describe 'PuppetDebugServer::DebugSession::PuppetSessionState' do
  let(:subject) { PuppetDebugServer::DebugSession::PuppetSessionState.new }

  describe '#actual' do
    it 'is an ActualPuppetSessionState' do
      expect(subject.actual).to be_a(PuppetDebugServer::DebugSession::ActualPuppetSessionState)
    end
  end

  describe '#saved' do
    it 'is a SavedPuppetSessionState' do
      expect(subject.saved).to be_a(PuppetDebugServer::DebugSession::SavedPuppetSessionState)
    end
  end

  describe '#clear!' do
    it 'clears saved state and returns self' do
      subject.saved.update!(session_exception: RuntimeError.new('boom'))
      result = subject.clear!
      expect(result).to eq(subject)
      expect(subject.saved.exception).to be_nil
    end
  end
end

describe 'PuppetDebugServer::DebugSession::ActualPuppetSessionState' do
  let(:subject) { PuppetDebugServer::DebugSession::ActualPuppetSessionState.new }

  describe '#initialize' do
    it 'starts with pops_depth_level of 0' do
      expect(subject.pops_depth_level).to eq(0)
    end
  end

  describe '#reset!' do
    it 'resets depth to 0 and clears compiler' do
      subject.increment_pops_depth
      subject.update_compiler(Object.new)
      subject.reset!
      expect(subject.pops_depth_level).to eq(0)
      expect(subject.compiler).to be_nil
    end
  end

  describe '#update_compiler' do
    it 'stores the compiler value' do
      compiler = Object.new
      subject.update_compiler(compiler)
      expect(subject.compiler).to eq(compiler)
    end
  end

  describe '#increment_pops_depth and #decrement_pops_depth' do
    it 'increments and decrements the depth' do
      subject.increment_pops_depth
      subject.increment_pops_depth
      expect(subject.pops_depth_level).to eq(2)
      subject.decrement_pops_depth
      expect(subject.pops_depth_level).to eq(1)
    end
  end
end

describe 'PuppetDebugServer::DebugSession::SavedPuppetSessionState' do
  let(:subject) { PuppetDebugServer::DebugSession::SavedPuppetSessionState.new }

  describe '#initialize' do
    it 'starts with an empty variable_cache' do
      expect(subject.variable_cache).to eq({})
    end
  end

  describe '#update!' do
    it 'updates all provided fields' do
      err = RuntimeError.new('test')
      subject.update!(
        session_exception: err,
        puppet_stacktrace: ['frame1'],
        pops_target: :some_target,
        scope: :some_scope,
        pops_depth_level: 3
      )
      expect(subject.exception).to eq(err)
      expect(subject.puppet_stacktrace).to eq(['frame1'])
      expect(subject.pops_target).to eq(:some_target)
      expect(subject.scope).to eq(:some_scope)
      expect(subject.pops_depth_level).to eq(3)
    end

    it 'does not overwrite existing values when option is nil' do
      err = RuntimeError.new('existing')
      subject.update!(session_exception: err)
      subject.update!(session_exception: nil)
      expect(subject.exception).to eq(err)
    end

    it 'returns self' do
      expect(subject.update!).to eq(subject)
    end
  end

  describe '#clear!' do
    it 'clears all state and resets variable_cache' do
      err = RuntimeError.new('boom')
      subject.update!(session_exception: err, puppet_stacktrace: ['f'], pops_depth_level: 2)
      result = subject.clear!
      expect(result).to eq(subject)
      expect(subject.exception).to be_nil
      expect(subject.puppet_stacktrace).to be_nil
      expect(subject.pops_target).to be_nil
      expect(subject.scope).to be_nil
      expect(subject.pops_depth_level).to be_nil
      expect(subject.variable_cache).to eq({})
    end
  end
end
