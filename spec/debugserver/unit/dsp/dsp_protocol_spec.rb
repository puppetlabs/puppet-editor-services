# frozen_string_literal: true

require 'spec_debug_helper'
# All DSP files are loaded transitively via puppet_debugserver in spec_debug_helper

describe 'DSP Protocol' do
  describe 'DSP module helper' do
    describe '.create_range' do
      it 'returns a hash describing a document range' do
        result = DSP.create_range(0, 1, 2, 3)
        expect(result).to eq(
          'start' => { 'line' => 0, 'character' => 1 },
          'end' => { 'line' => 2, 'character' => 3 }
        )
      end
    end
  end

  describe 'DSP::DSPBase subclasses' do
    let(:all_dsp_classes) do
      ObjectSpace.each_object(Class)
                 .select { |c| c < DSP::DSPBase }
                 .sort_by(&:name)
    end

    it 'discovers DSP protocol classes' do
      expect(all_dsp_classes).not_to be_empty
    end

    it 'every class can be instantiated without arguments' do
      all_dsp_classes.each do |klass|
        expect { klass.new }.not_to raise_error,
                                    "#{klass.name}.new raised an error"
      end
    end

    it 'every class returns self from from_h!(nil)' do
      all_dsp_classes.each do |klass|
        instance = klass.new
        expect(instance.from_h!(nil)).to eq(instance),
                                         "#{klass.name}#from_h!(nil) did not return self"
      end
    end

    it 'every class returns self from from_h!({})' do
      all_dsp_classes.each do |klass|
        instance = klass.new
        expect(instance.from_h!({})).to eq(instance),
                                        "#{klass.name}#from_h!({}) did not return self"
      end
    end

    it 'every class returns a Hash from to_h' do
      all_dsp_classes.each do |klass|
        instance = klass.new
        instance.from_h!({})
        result = instance.to_h
        expect(result).to be_a(Hash),
                          "#{klass.name}#to_h returned #{result.class}, not Hash"
      end
    end

    it 'every class returns a String from to_json' do
      all_dsp_classes.each do |klass|
        instance = klass.new
        instance.from_h!({})
        expect(instance.to_json).to be_a(String),
                                    "#{klass.name}#to_json did not return a String"
      end
    end

    it 'every class can be round-tripped through from_h!/to_h' do
      all_dsp_classes.each do |klass|
        instance = klass.new
        instance.from_h!({})
        h = instance.to_h
        instance2 = klass.new
        expect { instance2.from_h!(h) }.not_to raise_error,
                                               "#{klass.name}: round-trip from_h!(to_h result) raised an error"
      end
    end
  end

  describe 'nested object deserialization' do
    describe 'DSP::CancelRequest' do
      let(:request_hash) do
        {
          'seq' => 1,
          'type' => 'request',
          'command' => 'cancel',
          'arguments' => { 'requestId' => 5 }
        }
      end

      it 'creates a nested CancelArguments object' do
        req = DSP::CancelRequest.new(request_hash)
        expect(req.arguments).to be_a(DSP::CancelArguments)
        expect(req.arguments.requestId).to eq(5)
      end

      it 'serializes the nested object in to_h' do
        req = DSP::CancelRequest.new(request_hash)
        result = req.to_h
        expect(result['arguments']).to be_a(Hash)
        expect(result['arguments']['requestId']).to eq(5)
      end

      it 'leaves arguments nil when absent' do
        req = DSP::CancelRequest.new({ 'seq' => 1, 'type' => 'request', 'command' => 'cancel' })
        expect(req.arguments).to be_nil
      end
    end
  end

  describe 'typed array deserialization' do
    describe 'DSP::SetBreakpointsArguments' do
      let(:args_hash) do
        {
          'source' => { 'path' => '/example.pp' },
          'breakpoints' => [
            { 'line' => 5 },
            { 'line' => 10, 'condition' => 'x > 0' }
          ]
        }
      end

      it 'deserializes a typed array of SourceBreakpoint objects' do
        args = DSP::SetBreakpointsArguments.new(args_hash)
        expect(args.breakpoints).to be_an(Array)
        expect(args.breakpoints.length).to eq(2)
        expect(args.breakpoints.first).to be_a(DSP::SourceBreakpoint)
        expect(args.breakpoints.first.line).to eq(5)
      end

      it 'serializes the typed array in to_h' do
        args = DSP::SetBreakpointsArguments.new(args_hash)
        result = args.to_h
        expect(result['breakpoints']).to be_an(Array)
        expect(result['breakpoints'].first).to be_a(Hash)
        expect(result['breakpoints'].first['line']).to eq(5)
      end

      it 'returns nil for an absent typed array field' do
        args = DSP::SetBreakpointsArguments.new({})
        expect(args.breakpoints).to be_nil
      end
    end
  end

  describe 'optional fields' do
    describe 'DSP::CancelArguments' do
      it 'omits optional nil fields from to_h' do
        args = DSP::CancelArguments.new({})
        result = args.to_h
        expect(result).not_to have_key('requestId')
        expect(result).not_to have_key('progressId')
      end

      it 'includes optional fields when present' do
        args = DSP::CancelArguments.new({ 'requestId' => 42 })
        result = args.to_h
        expect(result).to have_key('requestId')
        expect(result['requestId']).to eq(42)
      end
    end
  end

  describe 'basic DSP message types' do
    describe 'DSP::ProtocolMessage' do
      it 'stores seq and type' do
        msg = DSP::ProtocolMessage.new({ 'seq' => 7, 'type' => 'request' })
        expect(msg.seq).to eq(7)
        expect(msg.type).to eq('request')
      end
    end

    describe 'DSP::Response' do
      it 'stores all response fields' do
        resp = DSP::Response.new({
                                   'seq' => 2,
                                   'type' => 'response',
                                   'request_seq' => 1,
                                   'success' => true,
                                   'command' => 'initialize',
                                   'body' => { 'supportsConfigurationDoneRequest' => true }
                                 })
        expect(resp.success).to be(true)
        expect(resp.command).to eq('initialize')
        expect(resp.body).to be_a(Hash)
      end

      it 'omits optional message and body fields when nil' do
        resp = DSP::Response.new({ 'request_seq' => 1, 'success' => true, 'command' => 'test' })
        result = resp.to_h
        expect(result).not_to have_key('message')
        expect(result).not_to have_key('body')
      end
    end
  end
end
