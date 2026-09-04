# frozen_string_literal: true

require 'spec_helper'
# lsp/lsp is loaded transitively when this spec runs via rake (--default-path spec/languageserver
# causes the languageserver spec_helper to be used, which loads puppet_languageserver).
# When run in isolation the root spec_helper is found instead, so require explicitly.
unless defined?(LSP)
  lib_dir = File.expand_path('../../../../lib', __dir__)
  $LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)
  require 'lsp/lsp'
end

describe 'LSP Protocol' do
  describe 'LSP module helper' do
    describe '.create_range' do
      it 'returns a hash describing a document range' do
        result = LSP.create_range(1, 2, 3, 4)
        expect(result).to eq(
          'start' => { 'line' => 1, 'character' => 2 },
          'end' => { 'line' => 3, 'character' => 4 }
        )
      end
    end
  end

  describe 'LSP::LSPBase subclasses' do
    let(:all_lsp_classes) do
      ObjectSpace.each_object(Class)
                 .select { |c| c < LSP::LSPBase }
                 .sort_by(&:name)
    end

    it 'discovers LSP protocol classes' do
      expect(all_lsp_classes).not_to be_empty
    end

    it 'every class can be instantiated without arguments' do
      all_lsp_classes.each do |klass|
        expect { klass.new }.not_to raise_error,
                                    "#{klass.name}.new raised an error"
      end
    end

    it 'every class returns self from from_h!(nil)' do
      all_lsp_classes.each do |klass|
        instance = klass.new
        expect(instance.from_h!(nil)).to eq(instance),
                                         "#{klass.name}#from_h!(nil) did not return self"
      end
    end

    it 'every class returns self from from_h!({})' do
      all_lsp_classes.each do |klass|
        instance = klass.new
        expect(instance.from_h!({})).to eq(instance),
                                        "#{klass.name}#from_h!({}) did not return self"
      end
    end

    it 'every class returns a Hash from to_h' do
      all_lsp_classes.each do |klass|
        instance = klass.new
        instance.from_h!({})
        result = instance.to_h
        expect(result).to be_a(Hash),
                          "#{klass.name}#to_h returned #{result.class}, not Hash"
      end
    end

    it 'every class returns a String from to_json' do
      all_lsp_classes.each do |klass|
        instance = klass.new
        instance.from_h!({})
        expect(instance.to_json).to be_a(String),
                                    "#{klass.name}#to_json did not return a String"
      end
    end

    it 'every class can be round-tripped through from_h!/to_h' do
      all_lsp_classes.each do |klass|
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
    describe 'LSP::Range' do
      let(:range_hash) do
        {
          'start' => { 'line' => 2, 'character' => 4 },
          'end' => { 'line' => 2, 'character' => 12 }
        }
      end

      it 'creates nested Position objects on from_h!' do
        range = LSP::Range.new(range_hash)
        expect(range.start).to be_a(LSP::Position)
        expect(range.send(:end)).to be_a(LSP::Position)
        expect(range.start.line).to eq(2)
        expect(range.start.character).to eq(4)
        expect(range.send(:end).character).to eq(12)
      end

      it 'serializes nested Position objects in to_h' do
        range = LSP::Range.new(range_hash)
        result = range.to_h
        expect(result['start']).to be_a(Hash)
        expect(result['start']['line']).to eq(2)
        expect(result['end']).to be_a(Hash)
        expect(result['end']['character']).to eq(12)
      end

      it 'does not instantiate nested objects when fields are absent' do
        range = LSP::Range.new({})
        expect(range.start).to be_nil
        expect(range.send(:end)).to be_nil
      end
    end

    describe 'LSP::Location' do
      let(:location_hash) do
        {
          'uri' => 'file:///example.pp',
          'range' => {
            'start' => { 'line' => 0, 'character' => 0 },
            'end' => { 'line' => 0, 'character' => 5 }
          }
        }
      end

      it 'creates a nested Range object' do
        location = LSP::Location.new(location_hash)
        expect(location.range).to be_a(LSP::Range)
        expect(location.range.start).to be_a(LSP::Position)
      end

      it 'serializes nested Range in to_h' do
        location = LSP::Location.new(location_hash)
        result = location.to_h
        expect(result['range']).to be_a(Hash)
        expect(result['range']['start']).to be_a(Hash)
      end
    end
  end

  describe 'typed array deserialization' do
    describe 'LSP::RegistrationParams' do
      let(:params_hash) do
        {
          'registrations' => [
            { 'id' => 'reg-1', 'method' => 'textDocument/didOpen' },
            { 'id' => 'reg-2', 'method' => 'textDocument/didClose' }
          ]
        }
      end

      it 'deserializes a typed array of Registration objects' do
        params = LSP::RegistrationParams.new(params_hash)
        expect(params.registrations).to be_an(Array)
        expect(params.registrations.length).to eq(2)
        expect(params.registrations.first).to be_a(LSP::Registration)
        expect(params.registrations.first.id).to eq('reg-1')
        expect(params.registrations.last.id).to eq('reg-2')
      end

      it 'serializes the typed array in to_h' do
        params = LSP::RegistrationParams.new(params_hash)
        result = params.to_h
        expect(result['registrations']).to be_an(Array)
        expect(result['registrations'].first).to be_a(Hash)
        expect(result['registrations'].first['id']).to eq('reg-1')
      end

      it 'returns nil for an absent typed array field' do
        params = LSP::RegistrationParams.new({})
        expect(params.registrations).to be_nil
      end
    end
  end

  describe 'optional fields' do
    describe 'LSP::Registration' do
      it 'omits optional nil fields from to_h output' do
        reg = LSP::Registration.new({ 'id' => 'r1', 'method' => 'test/method' })
        result = reg.to_h
        expect(result).not_to have_key('registerOptions')
      end

      it 'includes optional fields when they have a value' do
        reg = LSP::Registration.new({
                                      'id' => 'r1', 'method' => 'test/method', 'registerOptions' => { 'opt' => true }
                                    })
        result = reg.to_h
        expect(result).to have_key('registerOptions')
        expect(result['registerOptions']).to eq({ 'opt' => true })
      end
    end
  end

  describe 'field name aliasing (__lsp suffix)' do
    describe 'LSP::Registration' do
      it 'reads the method field via the method__lsp accessor' do
        reg = LSP::Registration.new({ 'id' => 'r1', 'method' => 'test/method' })
        expect(reg.method__lsp).to eq('test/method')
      end

      it 'serializes method__lsp back to the method key in to_h' do
        reg = LSP::Registration.new({ 'id' => 'r1', 'method' => 'test/method' })
        result = reg.to_h
        expect(result).to have_key('method')
        expect(result['method']).to eq('test/method')
        expect(result).not_to have_key('method__lsp')
      end
    end
  end
end
