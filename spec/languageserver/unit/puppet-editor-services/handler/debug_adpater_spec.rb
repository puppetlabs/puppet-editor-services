require 'spec_helper'

require 'puppet_editor_services/protocol/debug_adapter'
require 'puppet_editor_services/handler/debug_adapter'

describe 'PuppetEditorServices::Handler::DebugAdapter' do
  let(:server) do
    MockServer.new(
      {},
      {},
      { :class => PuppetEditorServices::Protocol::DebugAdapter },
      { :class => PuppetEditorServices::Handler::DebugAdapter }
    )
  end
  let(:subject) { server.handler_object }

  describe '.unhandled_exception' do
    it 'should respond to unhandled_exception' do
      expect(subject.respond_to?(:unhandled_exception)).to be(true)
    end

    context 'a request that raises an error' do
      let(:request_message) do
        ::PuppetEditorServices::Protocol::DebugAdapterMessages::Request.new.from_h!(
          'seq'      => 1,
          'command'   => 'initialize',
          'arguments' => nil
        )
      end
      let(:context) { {} }

      before(:each) do
        allow(subject).to receive(:request_initialize).and_raise('MockError')
      end

      it 'should call unhandled_exception' do
        expect(subject).to receive(:unhandled_exception)
        subject.handle(request_message, context)
      end
    end
  end

  describe '.handle' do
    before(:each) do
      allow(PuppetEditorServices).to receive(:log_message)
    end

    context 'for an unknown request' do
      let(:request_method) { 'foo_bar' }
      let(:message) do
        ::PuppetEditorServices::Protocol::DebugAdapterMessages::Request.new.from_h!(
          'seq'      => 1,
          'command'   => 'foo_bar',
          'arguments' => nil
        )
      end
      let(:context) { {} }

      it 'should log an error' do
        expect(PuppetEditorServices).to receive(:log_message).with(:error, /#{request_method}/)
        subject.handle(message, context)
      end

      it 'should return a Method Not Found error' do
        # This isn't stritly testing that it replies with this message, but it's a good proxy
        expect(PuppetEditorServices::Protocol::DebugAdapterMessages).to receive(:reply_error).with(message, String).and_call_original
        subject.handle(message, context)
      end

      it 'should return false' do
        expect(subject.handle(message, context)).to eq(false)
      end
    end
  end
end
