# frozen_string_literal: true

require 'spec_helper'
require 'puppet_editor_services/protocol/debug_adapter_messages'

describe 'PuppetEditorServices::Protocol::DebugAdapterMessages' do
  let(:msgs) { PuppetEditorServices::Protocol::DebugAdapterMessages }

  describe 'ProtocolMessage' do
    subject(:msg) { msgs::ProtocolMessage.new }

    it 'initializes with nil seq and type' do
      expect(msg.seq).to be_nil
      expect(msg.type).to be_nil
    end

    it 'populates fields via from_h!' do
      msg.from_h!({ 'seq' => 3, 'type' => 'request' })
      expect(msg.seq).to eq(3)
      expect(msg.type).to eq('request')
    end

    it 'handles nil hash in from_h!' do
      expect { msg.from_h!(nil) }.not_to raise_error
    end

    it 'serializes to a hash via to_h' do
      msg.from_h!({ 'seq' => 1, 'type' => 'event' })
      result = msg.to_h
      expect(result).to eq({ 'seq' => 1, 'type' => 'event' })
    end

    it 'serializes to JSON via to_json' do
      msg.from_h!({ 'seq' => 1, 'type' => 'event' })
      expect(msg.to_json).to be_a(String)
      expect(JSON.parse(msg.to_json)).to include('seq' => 1)
    end

    it 'can be instantiated with an initial hash' do
      msg2 = msgs::ProtocolMessage.new({ 'seq' => 5, 'type' => 'response' })
      expect(msg2.seq).to eq(5)
      expect(msg2.type).to eq('response')
    end
  end

  describe 'Request' do
    subject(:req) { msgs::Request.new }

    it 'sets type to request on initialization' do
      expect(req.type).to eq('request')
    end

    it 'populates command and arguments via from_h!' do
      req.from_h!({ 'seq' => 1, 'command' => 'initialize', 'arguments' => { 'foo' => 'bar' } })
      expect(req.command).to eq('initialize')
      expect(req.arguments).to eq({ 'foo' => 'bar' })
    end

    it 'handles nil arguments in from_h!' do
      req.from_h!({ 'seq' => 1, 'command' => 'initialize' })
      expect(req.arguments).to be_nil
    end

    it 'includes arguments in to_h when present' do
      req.from_h!({ 'seq' => 1, 'command' => 'launch', 'arguments' => { 'program' => '/a.pp' } })
      result = req.to_h
      expect(result['command']).to eq('launch')
      expect(result['arguments']).to eq({ 'program' => '/a.pp' })
    end

    it 'omits arguments from to_h when nil' do
      req.from_h!({ 'seq' => 1, 'command' => 'configurationDone' })
      result = req.to_h
      expect(result).not_to have_key('arguments')
    end

    it 'can be instantiated with an initial hash' do
      req2 = msgs::Request.new({ 'seq' => 2, 'command' => 'threads' })
      expect(req2.command).to eq('threads')
    end
  end

  describe 'Event' do
    subject(:evt) { msgs::Event.new }

    it 'sets type to event on initialization' do
      expect(evt.type).to eq('event')
    end

    it 'populates event name and body via from_h!' do
      evt.from_h!({ 'seq' => 1, 'event' => 'initialized', 'body' => { 'reason' => 'started' } })
      expect(evt.event).to eq('initialized')
      expect(evt.body).to eq({ 'reason' => 'started' })
    end

    it 'includes body in to_h when present' do
      evt.from_h!({ 'seq' => 1, 'event' => 'stopped', 'body' => { 'reason' => 'breakpoint' } })
      result = evt.to_h
      expect(result['event']).to eq('stopped')
      expect(result['body']).to eq({ 'reason' => 'breakpoint' })
    end

    it 'omits body from to_h when nil' do
      evt.from_h!({ 'seq' => 1, 'event' => 'initialized' })
      result = evt.to_h
      expect(result).not_to have_key('body')
    end
  end

  describe 'Response' do
    subject(:resp) { msgs::Response.new }

    it 'sets type to response on initialization' do
      expect(resp.type).to eq('response')
    end

    it 'populates all fields via from_h!' do
      resp.from_h!({
                     'seq' => 2,
                     'request_seq' => 1,
                     'success' => true,
                     'command' => 'initialize',
                     'message' => 'ok',
                     'body' => { 'result' => true }
                   })
      expect(resp.request_seq).to eq(1)
      expect(resp.success).to be(true)
      expect(resp.command).to eq('initialize')
      expect(resp.message).to eq('ok')
      expect(resp.body).to eq({ 'result' => true })
    end

    it 'includes message in to_h when present' do
      resp.from_h!({ 'request_seq' => 1, 'success' => false, 'command' => 'test', 'message' => 'oops' })
      result = resp.to_h
      expect(result['message']).to eq('oops')
    end

    it 'omits message from to_h when nil' do
      resp.from_h!({ 'request_seq' => 1, 'success' => true, 'command' => 'test' })
      result = resp.to_h
      expect(result).not_to have_key('message')
    end

    it 'omits body from to_h when nil' do
      resp.from_h!({ 'request_seq' => 1, 'success' => true, 'command' => 'test' })
      result = resp.to_h
      expect(result).not_to have_key('body')
    end

    it 'includes body in to_h when present' do
      resp.from_h!({ 'request_seq' => 1, 'success' => true, 'command' => 'test', 'body' => { 'x' => 1 } })
      result = resp.to_h
      expect(result['body']).to eq({ 'x' => 1 })
    end

    it 'can be instantiated with an initial hash' do
      resp2 = msgs::Response.new({ 'request_seq' => 5, 'success' => true, 'command' => 'launch' })
      expect(resp2.command).to eq('launch')
      expect(resp2.success).to be(true)
    end
  end

  describe 'factory methods' do
    let(:request) do
      msgs::Request.new({ 'seq' => 1, 'command' => 'initialize' })
    end

    describe '.reply_error' do
      it 'returns a Response with success false' do
        resp = msgs.reply_error(request, 'Something went wrong')
        expect(resp).to be_a(msgs::Response)
        expect(resp.success).to be(false)
        expect(resp.request_seq).to eq(1)
        expect(resp.command).to eq('initialize')
        expect(resp.message).to eq('Something went wrong')
      end

      it 'attaches a message object when provided' do
        err_obj = { 'id' => 1, 'format' => 'error' }
        resp = msgs.reply_error(request, 'err', err_obj)
        expect(resp.body).to eq({ 'error' => err_obj })
      end

      it 'works without optional arguments' do
        resp = msgs.reply_error(request)
        expect(resp.success).to be(false)
        expect(resp.message).to be_nil
      end
    end

    describe '.reply_success' do
      it 'returns a Response with success true' do
        resp = msgs.reply_success(request)
        expect(resp).to be_a(msgs::Response)
        expect(resp.success).to be(true)
        expect(resp.request_seq).to eq(1)
        expect(resp.command).to eq('initialize')
      end

      it 'attaches body content when provided' do
        resp = msgs.reply_success(request, { 'result' => 42 })
        expect(resp.body).to eq({ 'result' => 42 })
      end

      it 'leaves body nil when not provided' do
        resp = msgs.reply_success(request)
        expect(resp.body).to be_nil
      end
    end

    describe '.new_event' do
      it 'returns an Event with the given name' do
        evt = msgs.new_event('initialized')
        expect(evt).to be_a(msgs::Event)
        expect(evt.event).to eq('initialized')
      end

      it 'attaches body content when provided' do
        evt = msgs.new_event('stopped', { 'reason' => 'breakpoint' })
        expect(evt.body).to eq({ 'reason' => 'breakpoint' })
      end

      it 'leaves body nil when not provided' do
        evt = msgs.new_event('initialized')
        expect(evt.body).to be_nil
      end
    end
  end
end
