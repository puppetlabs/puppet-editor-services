require 'spec_helper'

require 'puppet_editor_services/handler/json_rpc'

describe 'PuppetEditorServices::Handler::JsonRPC' do
  let(:server) do
    MockServer.new(
      {},
      {},
      { :class => PuppetEditorServices::Protocol::JsonRPC },
      { :class => PuppetEditorServices::Handler::JsonRPC }
    )
  end
  let(:subject) { server.handler_object }

  describe '.unhandled_exception' do
    it 'should respond to unhandled_exception' do
      expect(subject.respond_to?(:unhandled_exception)).to be(true)
    end

    context 'a request that raises an error' do
      let(:request_message) do
        ::PuppetEditorServices::Protocol::JsonRPCMessages::RequestMessage.new.from_h!(
          'id'      => 1,
          'method'  => 'initialize',
          'params'  => nil
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

    context 'a notification that raises an error' do
      let(:notification_message) do
        ::PuppetEditorServices::Protocol::JsonRPCMessages::NotificationMessage.new.from_h!(
          'method'  => 'initialized',
          'params'  => nil
        )
      end
      let(:context) { {} }

      before(:each) do
        allow(subject).to receive(:notification_initialized).and_raise('MockError')
      end

      it 'should call unhandled_exception' do
        expect(subject).to receive(:unhandled_exception)
        subject.handle(notification_message, context)
      end
    end

    context 'a response that raises an error' do
      let(:response_message) do
        ::PuppetEditorServices::Protocol::JsonRPCMessages::ResponseMessage.new.from_h!(
          'id'      => 1,
          'result'  => 'success'
        )
      end
      let(:request_message) do
        ::PuppetEditorServices::Protocol::JsonRPCMessages::RequestMessage.new.from_h!(
          'id'      => 1,
          'method'  => 'mock',
          'params'  => nil
        )
      end
      let(:context) { { :request => request_message } }

      before(:each) do
        allow(subject).to receive(:response_mock).and_raise('MockError')
      end

      it 'should call unhandled_exception' do
        expect(subject).to receive(:unhandled_exception)
        subject.handle(response_message, context)
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
        ::PuppetEditorServices::Protocol::JsonRPCMessages::RequestMessage.new.from_h!(
          'id'      => 1,
          'method'  => request_method,
          'params'  => nil
        )
      end
      let(:context) { {} }

      it 'should log an error' do
        expect(PuppetEditorServices).to receive(:log_message).with(:error, /#{request_method}/)
        subject.handle(message, context)
      end

      it 'should return a Method Not Found error' do
        # This isn't stritly testing that it replies with this message, but it's a good proxy
        expect(PuppetEditorServices::Protocol::JsonRPCMessages).to receive(:reply_method_not_found).with(message).and_call_original
        subject.handle(message, context)
      end

      it 'should return false' do
        expect(subject.handle(message, context)).to eq(false)
      end

      context 'which is a protocol dependant message' do
        let(:request_method) { '$/foo_bar' }

        it 'should log a debug message' do
          expect(PuppetEditorServices).to receive(:log_message).with(:debug, /\$\/foo_bar/)
          subject.handle(message, context)
        end

        it 'should return a Method Not Found error' do
          # This isn't stritly testing that it replies with this message, but it's a good proxy
          expect(PuppetEditorServices::Protocol::JsonRPCMessages).to receive(:reply_method_not_found).with(message).and_call_original
          subject.handle(message, context)
        end

        it 'should return false' do
          expect(subject.handle(message, context)).to eq(false)
        end
      end
    end

    context 'for an unknown notification' do
      let(:request_method) { 'foo_bar' }
      let(:message) do
        ::PuppetEditorServices::Protocol::JsonRPCMessages::NotificationMessage.new.from_h!(
          'method'  => request_method,
          'params'  => nil
        )
      end
      let(:context) { {} }

      it 'should log an error' do
        expect(PuppetEditorServices).to receive(:log_message).with(:error, /#{request_method}/)
        subject.handle(message, context)
      end

      it 'should return false' do
        expect(subject.handle(message, context)).to eq(false)
      end

      context 'which is a protocol dependant message' do
        let(:request_method) { '$/foo_bar' }

        it 'should log a debug message' do
          expect(PuppetEditorServices).to receive(:log_message).with(:debug, /\$\/foo_bar/)
          subject.handle(message, context)
        end

        it 'should return false' do
          expect(subject.handle(message, context)).to eq(false)
        end
      end
    end

    context 'for an unknown response' do
      let(:request_method) { 'foo_bar' }
      let(:message) do
        ::PuppetEditorServices::Protocol::JsonRPCMessages::ResponseMessage.new.from_h!(
          'id'      => 1,
          'result'  => 'success'
        )
      end
      let(:request_message) do
        ::PuppetEditorServices::Protocol::JsonRPCMessages::RequestMessage.new.from_h!(
          'id'      => 1,
          'method'  => request_method,
          'params'  => nil
        )
      end
      let(:context) { { :request => request_message } }

      it 'should log an error' do
        expect(PuppetEditorServices).to receive(:log_message).with(:error, /#{request_method}/)
        subject.handle(message, context)
      end

      it 'should return false' do
        expect(subject.handle(message, context)).to eq(false)
      end
    end
  end
end
