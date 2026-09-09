require 'spec_debug_helper'

describe 'PuppetDebugServer::DebugSession::FlowControl' do
  let(:saved_state) { PuppetDebugServer::DebugSession::SavedPuppetSessionState.new }
  let(:puppet_session_state) do
    state = instance_double(PuppetDebugServer::DebugSession::PuppetSessionState)
    allow(state).to receive(:saved).and_return(saved_state)
    state
  end
  let(:debug_session) do
    ds = instance_double(PuppetDebugServer::PuppetDebugSession)
    allow(ds).to receive(:puppet_session_state).and_return(puppet_session_state)
    ds
  end
  let(:subject) { PuppetDebugServer::DebugSession::FlowControl.new(debug_session) }

  before(:each) do
    allow(PuppetDebugServer).to receive(:log_message)
  end

  describe '#flag?' do
    it 'returns false for an unset flag' do
      expect(subject.flag?(:start_puppet)).to be false
    end

    it 'returns false for an unknown flag' do
      expect(subject.flag?(:no_such_flag)).to be false
    end

    it 'returns true after asserting the flag' do
      subject.assert_flag(:start_puppet)
      expect(subject.flag?(:start_puppet)).to be true
    end
  end

  describe '#assert_flag' do
    it 'sets the named flag to true' do
      subject.assert_flag(:suppress_log_messages)
      expect(subject.flag?(:suppress_log_messages)).to be true
    end

    it 'auto-sets start_puppet when both client_completed_configuration and session_setup are asserted' do
      subject.assert_flag(:session_setup)
      subject.assert_flag(:client_completed_configuration)
      expect(subject.flag?(:start_puppet)).to be true
    end

    it 'does not set start_puppet if puppet_started is already true' do
      subject.assert_flag(:puppet_started)
      subject.assert_flag(:session_setup)
      subject.assert_flag(:client_completed_configuration)
      expect(subject.flag?(:start_puppet)).to be false
    end
  end

  describe '#unassert_flag' do
    it 'removes an asserted flag' do
      subject.assert_flag(:session_paused)
      subject.unassert_flag(:session_paused)
      expect(subject.flag?(:session_paused)).to be false
    end

    it 'does not allow unsetting the :terminate flag' do
      subject.assert_flag(:terminate)
      subject.unassert_flag(:terminate)
      expect(subject.flag?(:terminate)).to be true
    end
  end

  describe '#terminate?' do
    it 'returns nil/falsey when not terminated' do
      expect(subject.terminate?).to be_falsey
    end

    it 'returns truthy after asserting terminate' do
      subject.assert_flag(:terminate)
      expect(subject.terminate?).to be_truthy
    end
  end

  describe '#session_active?' do
    it 'returns false when puppet_started flag is not set' do
      expect(subject.session_active?).to be false
    end

    it 'returns true when puppet_started flag is set' do
      subject.assert_flag(:puppet_started)
      expect(subject.session_active?).to be true
    end
  end

  describe '#session_paused?' do
    it 'returns false when session_paused flag is not set' do
      expect(subject.session_paused?).to be false
    end

    it 'returns true when session_paused flag is set' do
      subject.assert_flag(:session_paused)
      expect(subject.session_paused?).to be true
    end
  end

  describe '#continue!' do
    before(:each) do
      subject.assert_flag(:session_paused)
      saved_state.update!(session_exception: RuntimeError.new('paused'))
    end

    it 'unpauses the session' do
      subject.continue!
      expect(subject.session_paused?).to be false
    end

    it 'sets run_mode to :run' do
      subject.continue!
      expect(subject.run_mode.mode).to eq(:run)
    end

    it 'clears the saved state' do
      subject.continue!
      expect(saved_state.exception).to be_nil
    end
  end

  describe '#next!' do
    before(:each) do
      subject.assert_flag(:session_paused)
      saved_state.update!(pops_depth_level: 4)
    end

    it 'unpauses the session' do
      subject.next!
      expect(subject.session_paused?).to be false
    end

    it 'sets run_mode to :next with saved depth level' do
      subject.next!
      expect(subject.run_mode.mode).to eq(:next)
      expect(subject.run_mode.options[:pops_depth_level]).to eq(4)
    end
  end

  describe '#step_in!' do
    before(:each) do
      subject.assert_flag(:session_paused)
    end

    it 'unpauses the session' do
      subject.step_in!
      expect(subject.session_paused?).to be false
    end

    it 'sets run_mode to :stepin' do
      subject.step_in!
      expect(subject.run_mode.mode).to eq(:stepin)
    end
  end

  describe '#step_out!' do
    before(:each) do
      subject.assert_flag(:session_paused)
      saved_state.update!(pops_depth_level: 2)
    end

    it 'unpauses the session' do
      subject.step_out!
      expect(subject.session_paused?).to be false
    end

    it 'sets run_mode to :stepout with saved depth level' do
      subject.step_out!
      expect(subject.run_mode.mode).to eq(:stepout)
      expect(subject.run_mode.options[:pops_depth_level]).to eq(2)
    end
  end
end
