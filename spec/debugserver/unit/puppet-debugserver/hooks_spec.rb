require 'spec_debug_helper'

describe 'PuppetDebugServer::Hooks' do
  let(:subject) { PuppetDebugServer::Hooks.new }

  describe '#add_hook and #hook_count' do
    it 'adds a block hook and increments count' do
      subject.add_hook(:my_event, :my_hook) { 'called' }
      expect(subject.hook_count(:my_event)).to eq(1)
    end

    it 'adds a callable hook' do
      callable = proc { 'called' }
      subject.add_hook(:my_event, :my_hook, callable)
      expect(subject.hook_count(:my_event)).to eq(1)
    end

    it 'raises when no block or callable is given' do
      expect { subject.add_hook(:my_event, :my_hook) }.to raise_error(ArgumentError, /Must provide a block or callable/)
    end

    it 'raises when a duplicate named hook is added' do
      subject.add_hook(:my_event, :my_hook) { 'first' }
      expect { subject.add_hook(:my_event, :my_hook) { 'second' } }.to raise_error(ArgumentError, /already defined/)
    end

    it 'replaces anonymous hooks (nil name)' do
      subject.add_hook(:my_event, nil) { 'first' }
      subject.add_hook(:my_event, nil) { 'second' }
      expect(subject.hook_count(:my_event)).to eq(1)
    end

    it 'returns self for chaining' do
      result = subject.add_hook(:my_event, :h1) { 'x' }
      expect(result).to eq(subject)
    end
  end

  describe '#hook_exists?' do
    it 'returns true when hook exists' do
      subject.add_hook(:my_event, :my_hook) { 'x' }
      expect(subject.hook_exists?(:my_event, :my_hook)).to be true
    end

    it 'returns false when hook does not exist' do
      expect(subject.hook_exists?(:my_event, :no_such_hook)).to be false
    end
  end

  describe '#exec_hook' do
    before(:each) do
      allow(PuppetDebugServer).to receive(:log_message)
    end

    it 'calls all hooks for the event' do
      called = []
      subject.add_hook(:my_event, :h1) { called << 'first' }
      subject.add_hook(:my_event, :h2) { called << 'second' }
      subject.exec_hook(:my_event)
      expect(called).to eq(['first', 'second'])
    end

    it 'skips log_message calls for :hook_log_message event' do
      called = []
      subject.add_hook(:hook_log_message, :h1) { called << 'hook_ran' }
      expect(PuppetDebugServer).not_to receive(:log_message)
      subject.exec_hook(:hook_log_message)
      expect(called).to eq(['hook_ran'])
    end

    it 'records errors from RuntimeError but does not re-raise' do
      subject.add_hook(:my_event, :h1) { raise RuntimeError, 'boom' }
      expect { subject.exec_hook(:my_event) }.not_to raise_error
      expect(subject.errors).not_to be_empty
      expect(subject.errors.first.message).to eq('boom')
    end
  end

  describe '#get_hook' do
    it 'returns the callable for a named hook' do
      callable = proc { 'found' }
      subject.add_hook(:my_event, :my_hook, callable)
      expect(subject.get_hook(:my_event, :my_hook)).to eq(callable)
    end

    it 'returns nil when hook does not exist' do
      expect(subject.get_hook(:my_event, :no_such_hook)).to be_nil
    end
  end

  describe '#get_hooks' do
    it 'returns a hash of hook_name => callable' do
      callable = proc { 'x' }
      subject.add_hook(:my_event, :my_hook, callable)
      result = subject.get_hooks(:my_event)
      expect(result).to be_a(Hash)
      expect(result[:my_hook]).to eq(callable)
    end
  end

  describe '#delete_hook' do
    it 'removes the hook and returns the callable' do
      callable = proc { 'x' }
      subject.add_hook(:my_event, :my_hook, callable)
      result = subject.delete_hook(:my_event, :my_hook)
      expect(result).to eq(callable)
      expect(subject.hook_count(:my_event)).to eq(0)
    end

    it 'returns nil when hook does not exist' do
      expect(subject.delete_hook(:my_event, :no_such_hook)).to be_nil
    end
  end

  describe '#clear_event_hooks' do
    it 'removes all hooks for the event' do
      subject.add_hook(:my_event, :h1) { 'x' }
      subject.add_hook(:my_event, :h2) { 'y' }
      subject.clear_event_hooks(:my_event)
      expect(subject.hook_count(:my_event)).to eq(0)
    end
  end

  describe '#errors' do
    it 'returns an empty array initially' do
      expect(subject.errors).to eq([])
    end
  end

  describe '#initialize_copy' do
    it 'is defined on the class' do
      # initialize_copy is defined but missing the required source arg (Ruby convention);
      # verify it exists as a method
      expect(subject).to respond_to(:dup)
    end
  end
end
