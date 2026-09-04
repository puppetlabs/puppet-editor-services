# frozen_string_literal: true

require 'spec_helper'
require 'puppet_editor_services/protocol/json_rpc'

describe 'PuppetEditorServices::Protocol::JsonRPCMessages' do
  let(:msgs) { PuppetEditorServices::Protocol::JsonRPCMessages }
  let(:rpc)  { PuppetEditorServices::Protocol::JsonRPC }

  describe 'Message' do
    subject(:msg) { msgs::Message.new }

    it 'initializes with the default JSONRPC version' do
      expect(msg.jsonrpc).to eq(rpc::JSONRPC_VERSION)
    end

    it 'updates jsonrpc from from_h! when provided' do
      msg.from_h!({ 'jsonrpc' => '1.0' })
      expect(msg.jsonrpc).to eq('1.0')
    end

    it 'does not override jsonrpc when value is nil in from_h!' do
      msg.from_h!({ 'jsonrpc' => nil })
      expect(msg.jsonrpc).to eq(rpc::JSONRPC_VERSION)
    end

    it 'handles an empty hash in from_h!' do
      expect { msg.from_h!({}) }.not_to raise_error
    end

    it 'handles nil in from_h!' do
      expect { msg.from_h!(nil) }.not_to raise_error
    end

    it 'serializes to a hash via to_h' do
      result = msg.to_h
      expect(result).to have_key('jsonrpc')
      expect(result['jsonrpc']).to eq(rpc::JSONRPC_VERSION)
    end

    it 'serializes to JSON via to_json' do
      expect(msg.to_json).to be_a(String)
      expect(JSON.parse(msg.to_json)).to include('jsonrpc' => rpc::JSONRPC_VERSION)
    end
  end

  describe 'RequestMessage' do
    subject(:req) { msgs::RequestMessage.new }

    it 'populates id, method, and params from from_h!' do
      req.from_h!({ 'id' => 42, 'method' => 'puppet/getVersion', 'params' => { 'x' => 1 } })
      expect(req.id).to eq(42)
      expect(req.rpc_method).to eq('puppet/getVersion')
      expect(req.params).to eq({ 'x' => 1 })
    end

    it 'maps the method JSON key to the rpc_method accessor' do
      req.from_h!({ 'id' => 1, 'method' => 'initialize' })
      expect(req.rpc_method).to eq('initialize')
    end

    it 'includes id, method, and params in to_h' do
      req.from_h!({ 'id' => 1, 'method' => 'initialize', 'params' => nil })
      result = req.to_h
      expect(result).to include('id' => 1, 'method' => 'initialize', 'params' => nil)
      expect(result['jsonrpc']).to eq(rpc::JSONRPC_VERSION)
    end

    it 'can be instantiated with an initial hash' do
      req2 = msgs::RequestMessage.new({ 'id' => 5, 'method' => 'shutdown' })
      expect(req2.id).to eq(5)
      expect(req2.rpc_method).to eq('shutdown')
    end
  end

  describe 'NotificationMessage' do
    subject(:notif) { msgs::NotificationMessage.new }

    it 'populates method and params from from_h!' do
      notif.from_h!({ 'method' => 'initialized', 'params' => {} })
      expect(notif.rpc_method).to eq('initialized')
      expect(notif.params).to eq({})
    end

    it 'includes params in to_h when present' do
      notif.from_h!({ 'method' => 'textDocument/didChange', 'params' => { 'uri' => 'file:///a.pp' } })
      result = notif.to_h
      expect(result['method']).to eq('textDocument/didChange')
      expect(result['params']).to eq({ 'uri' => 'file:///a.pp' })
    end

    it 'omits params from to_h when nil' do
      notif.from_h!({ 'method' => 'initialized' })
      result = notif.to_h
      expect(result).not_to have_key('params')
    end

    it 'includes the jsonrpc key in to_h' do
      notif.from_h!({ 'method' => 'initialized' })
      result = notif.to_h
      expect(result['jsonrpc']).to eq(rpc::JSONRPC_VERSION)
    end
  end

  describe 'ResponseMessage' do
    subject(:resp) { msgs::ResponseMessage.new }

    describe 'successful response' do
      it 'deserializes a successful response' do
        resp.from_h!({ 'id' => 1, 'result' => 'ok' })
        expect(resp.id).to eq(1)
        expect(resp.result).to eq('ok')
        expect(resp.is_successful).to be(true)
      end

      it 'includes result in to_h for successful responses' do
        resp.from_h!({ 'id' => 1, 'result' => { 'value' => 42 } })
        result = resp.to_h
        expect(result).to have_key('result')
        expect(result['result']).to eq({ 'value' => 42 })
        expect(result).not_to have_key('error')
      end

      it 'includes result in to_h even when result is null' do
        resp.from_h!({ 'id' => 1, 'result' => nil })
        result = resp.to_h
        expect(result).to have_key('result')
        expect(result['result']).to be_nil
      end
    end

    describe 'error response' do
      it 'deserializes an error response' do
        resp.from_h!({ 'id' => 1, 'error' => { 'code' => -32_600, 'message' => 'Invalid Request' } })
        expect(resp.is_successful).to be(false)
        expect(resp.error).to eq({ 'code' => -32_600, 'message' => 'Invalid Request' })
      end

      it 'includes error in to_h for error responses' do
        resp.from_h!({ 'id' => 1, 'error' => { 'code' => -32_601, 'message' => 'Not Found' } })
        result = resp.to_h
        expect(result).to have_key('error')
        expect(result).not_to have_key('result')
      end
    end

    describe 'manually constructed response' do
      it 'serializes as success when is_successful is true' do
        resp.id = 1
        resp.result = 'value'
        resp.is_successful = true
        result = resp.to_h
        expect(result).to have_key('result')
        expect(result).not_to have_key('error')
      end

      it 'serializes as error when is_successful is false' do
        resp.id = 1
        resp.error = { 'code' => -32_603, 'message' => 'Internal Error' }
        resp.is_successful = false
        result = resp.to_h
        expect(result).to have_key('error')
        expect(result).not_to have_key('result')
      end
    end
  end

  describe 'module-level factory methods' do
    let(:request) do
      msgs::RequestMessage.new({ 'id' => 10, 'method' => 'puppet/getVersion' })
    end

    describe '.reply_result' do
      it 'creates a successful ResponseMessage' do
        resp = msgs.reply_result(request, 'v1.2.3')
        expect(resp).to be_a(msgs::ResponseMessage)
        expect(resp.id).to eq(10)
        expect(resp.is_successful).to be(true)
        expect(resp.result).to eq('v1.2.3')
      end
    end

    describe '.reply_error' do
      it 'creates an error ResponseMessage' do
        resp = msgs.reply_error(request, -32_600, 'Bad Request')
        expect(resp).to be_a(msgs::ResponseMessage)
        expect(resp.id).to eq(10)
        expect(resp.is_successful).to be(false)
        expect(resp.error).to include('code' => -32_600, 'message' => 'Bad Request')
      end
    end

    describe '.reply_error_by_id' do
      it 'creates an error ResponseMessage by explicit id' do
        resp = msgs.reply_error_by_id(99, -32_603, 'Internal Error')
        expect(resp).to be_a(msgs::ResponseMessage)
        expect(resp.id).to eq(99)
        expect(resp.error['code']).to eq(-32_603)
      end
    end

    describe '.reply_method_not_found' do
      it 'creates a method-not-found error response' do
        resp = msgs.reply_method_not_found(request)
        expect(resp.is_successful).to be(false)
        expect(resp.error['code']).to eq(rpc::CODE_METHOD_NOT_FOUND)
      end

      it 'uses a custom message when provided' do
        resp = msgs.reply_method_not_found(request, 'Custom not found message')
        expect(resp.error['message']).to eq('Custom not found message')
      end
    end

    describe '.new_notification' do
      it 'creates a NotificationMessage with the given method and params' do
        notif = msgs.new_notification('textDocument/publishDiagnostics', { 'uri' => 'file:///a.pp' })
        expect(notif).to be_a(msgs::NotificationMessage)
        expect(notif.rpc_method).to eq('textDocument/publishDiagnostics')
        expect(notif.params).to eq({ 'uri' => 'file:///a.pp' })
      end
    end

    describe '.new_request' do
      it 'creates a RequestMessage with the given id, method, and params' do
        req = msgs.new_request(7, 'window/showMessageRequest', { 'message' => 'hello' })
        expect(req).to be_a(msgs::RequestMessage)
        expect(req.id).to eq(7)
        expect(req.rpc_method).to eq('window/showMessageRequest')
        expect(req.params).to eq({ 'message' => 'hello' })
      end
    end
  end
end
