require 'spec_debug_helper'

describe 'PuppetDebugServer::DebugSession::PuppetSessionRunMode' do
  let(:subject) { PuppetDebugServer::DebugSession::PuppetSessionRunMode.new }

  describe '#initialize' do
    it 'defaults to :run mode' do
      expect(subject.mode).to eq(:run)
    end

    it 'defaults to empty options' do
      expect(subject.options).to eq({})
    end

    it 'raises for invalid modes' do
      expect { PuppetDebugServer::DebugSession::PuppetSessionRunMode.new(:invalid) }.to raise_error(/Invalid mode/)
    end

    it 'accepts all valid modes' do
      %i[run stepin next stepout].each do |mode|
        expect { PuppetDebugServer::DebugSession::PuppetSessionRunMode.new(mode) }.not_to raise_error
      end
    end
  end

  describe '#run!' do
    it 'sets mode to :run and clears options' do
      subject.next!(5)
      subject.run!
      expect(subject.mode).to eq(:run)
      expect(subject.options).to eq({})
    end
  end

  describe '#next!' do
    it 'sets mode to :next with pops_depth_level' do
      subject.next!(3)
      expect(subject.mode).to eq(:next)
      expect(subject.options[:pops_depth_level]).to eq(3)
    end
  end

  describe '#step_in!' do
    it 'sets mode to :stepin and clears options' do
      subject.next!(5)
      subject.step_in!
      expect(subject.mode).to eq(:stepin)
      expect(subject.options).to eq({})
    end
  end

  describe '#step_out!' do
    it 'sets mode to :stepout with pops_depth_level' do
      subject.step_out!(7)
      expect(subject.mode).to eq(:stepout)
      expect(subject.options[:pops_depth_level]).to eq(7)
    end
  end
end
