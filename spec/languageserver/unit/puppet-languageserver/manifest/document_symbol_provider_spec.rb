require 'spec_helper'

RSpec::Matchers.define :be_document_symbol do |name, kind, start_line, start_char, end_line, end_char|
  match do |actual|
    actual.name == name &&
    actual.kind == kind &&
    actual.range.start.line == start_line &&
    actual.range.start.character == start_char &&
    actual.range.end.line == end_line &&
    actual.range.end.character == end_char
  end

  failure_message do |actual|
    "expected that symbol called '#{actual['name']}' of type '#{actual['kind']}' located at " +
      "(#{actual['range']['start']['line']}, #{actual['range']['start']['character']}, " +
      "#{actual['range']['end']['line']}, #{actual['range']['end']['character']}) would be " +
      "a document symbol called '#{name}', of type '#{kind}' located at (#{start_line}, #{start_char}, #{end_line}, #{end_char})"
  end

  description do
    "be a document symbol called '#{name}' of type #{kind} located at #{start_line}, #{start_char}, #{end_line}, #{end_char}"
  end
end

RSpec::Matchers.define :be_symbol_information do |name, kind|
  match do |actual|
    actual.name == name &&
    actual.kind == kind
  end

  failure_message do |actual|
    "expected that symbol called '#{actual.name}' of type '#{actual.kind}' would be " +
      "a symbol called '#{name}', of type '#{kind}'"
  end

  description do
    "be a document symbol called '#{name}' of type #{kind} located at #{start_line}, #{start_char}, #{end_line}, #{end_char}"
  end
end

describe 'PuppetLanguageServer::Manifest::DocumentSymbolProvider' do
  let(:subject) { PuppetLanguageServer::Manifest::DocumentSymbolProvider }

  describe '#workspace_symbols' do
    let(:cache) { PuppetLanguageServer::SessionState::ObjectCache.new }

    before(:each) do
      # Add test objects
      origin = :default
      cache.import_sidecar_list!([random_sidecar_puppet_class(:class1)], :class, origin)
      cache.import_sidecar_list!([random_sidecar_puppet_function(:func1)], :function, origin)
      cache.import_sidecar_list!([random_sidecar_puppet_type(:type1)], :type, origin)
      cache.import_sidecar_list!([random_sidecar_puppet_datatype(:datatype1)], :datatype, origin)
      cache.import_sidecar_list!([random_sidecar_fact(:fact1)], :fact, origin)
    end

    it 'should emit all known objects for an empty query' do
      result = subject.workspace_symbols(nil, cache)

      expect(result[0]).to be_symbol_information('class1', LSP::SymbolKind::CLASS)
      expect(result[1]).to be_symbol_information('func1', LSP::SymbolKind::FUNCTION)
      expect(result[2]).to be_symbol_information('type1', LSP::SymbolKind::METHOD)
      expect(result[3]).to be_symbol_information('datatype1', LSP::SymbolKind::NAMESPACE)

      all_cache_names = []
      cache.all_objects { |key, _| all_cache_names << key.to_s }
      # Facts are not output
      expect(result.count).to eq(all_cache_names.count - 1)
    end

    it 'should only emit objects that match a simple text query' do
      result = subject.workspace_symbols('func', cache)

      expect(result.count).to eq(1)
      expect(result[0]).to be_symbol_information('func1', LSP::SymbolKind::FUNCTION)
    end

    context 'when the cache contains an object of unknown type' do
      it 'logs a warning and skips the unknown object' do
        mock_cache = instance_double(PuppetLanguageServer::SessionState::ObjectCache)
        allow(mock_cache).to receive(:all_objects).and_yield(:unknown_key, Object.new)
        allow(PuppetLanguageServer).to receive(:log_message)
        expect(PuppetLanguageServer).to receive(:log_message).with(:warn, /Unknown object type/)
        result = subject.workspace_symbols(nil, mock_cache)
        expect(result).to be_empty
      end
    end
  end

  context 'with Puppet 4.0 and below', :if => Gem::Version.new(Puppet.version) < Gem::Version.new('5.0.0') do
    describe '#extract_document_symbols' do
      it 'should always return an empty array' do
        content = <<-EOT
        class foo {
          user { 'alice':
          }
        }
        EOT
        result = subject.extract_document_symbols(content)

        expect(result).to eq([])
      end
    end
  end

  context 'with Puppet 5.0 and above', :if => Gem::Version.new(Puppet.version) >= Gem::Version.new('5.0.0') do
    describe '#extract_document_symbols' do
      context 'Given a Puppet Plan', :if => Puppet.tasks_supported? do
        let(:content) { <<-EOT
          plan mymodule::my_plan(
          ) {
          }
          EOT
        }
        it "should not raise an error" do
          result = subject.extract_document_symbols(content, { :tasks_mode => true})
        end
      end

      it 'should find a class in the document root' do
        content = "class foo {\n}"
        result = subject.extract_document_symbols(content)
        expect(result.count).to eq(1)
        expect(result[0]).to be_document_symbol('foo', LSP::SymbolKind::CLASS, 0, 0, 1, 1)
      end

      it 'should find a resource in the document root' do
        content = "user { 'alice':\n}"
        result = subject.extract_document_symbols(content)

        expect(result.count).to eq(1)
        expect(result[0]).to be_document_symbol("user: 'alice'", LSP::SymbolKind::METHOD, 0, 0, 1, 1)
      end

      it 'should find a single line class in the document root' do
        content = "class foo(String $var1 = 'value1', String $var2 = 'value2') {\n}"
        result = subject.extract_document_symbols(content)

        expect(result.count).to eq(1)
        expect(result[0]).to be_document_symbol('foo', LSP::SymbolKind::CLASS, 0, 0, 1, 1)
        expect(result[0].children.count).to eq(2)
        expect(result[0].children[0]).to be_document_symbol('$var1', LSP::SymbolKind::PROPERTY, 0, 17, 0, 22)
        expect(result[0].children[1]).to be_document_symbol('$var2', LSP::SymbolKind::PROPERTY, 0, 42, 0, 47)
      end

      it 'should find a multi line class in the document root' do
        content = "class foo(\n  String $var1 = 'value1',\n  String $var2 = 'value2',\n) {\n}"
        result = subject.extract_document_symbols(content)

        expect(result.count).to eq(1)
        expect(result[0]).to be_document_symbol('foo', LSP::SymbolKind::CLASS, 0, 0, 4, 1)
        expect(result[0].children.count).to eq(2)
        expect(result[0].children[0]).to be_document_symbol('$var1', LSP::SymbolKind::PROPERTY, 1, 9, 1, 14)
        expect(result[0].children[1]).to be_document_symbol('$var2', LSP::SymbolKind::PROPERTY, 2, 9, 2, 14)
      end

      it 'should find a simple resource in a class' do
        content = "class foo {\n  user { 'alice':\n  }\n}"
        result = subject.extract_document_symbols(content)

        expect(result.count).to eq(1)
        expect(result[0]).to be_document_symbol('foo', LSP::SymbolKind::CLASS, 0, 0, 3, 1)
        expect(result[0].children.count).to eq(1)
        expect(result[0].children[0]).to be_document_symbol("user: 'alice'", LSP::SymbolKind::METHOD, 1, 2, 2, 3)
      end

      it 'should find a defined type in the document root' do
        content = "define mymodule::mytype() {\n}"
        result = subject.extract_document_symbols(content)

        expect(result.count).to eq(1)
        expect(result[0].name).to eq('mymodule::mytype')
        expect(result[0].kind).to eq(LSP::SymbolKind::CLASS)
      end

      it 'should find a defined type with parameters' do
        content = "define mymodule::mytype(\n  String $param1,\n) {\n}"
        result = subject.extract_document_symbols(content)

        expect(result.count).to eq(1)
        expect(result[0].name).to eq('mymodule::mytype')
        expect(result[0].kind).to eq(LSP::SymbolKind::CLASS)
        expect(result[0].children.count).to eq(1)
        expect(result[0].children[0].name).to eq('$param1')
        expect(result[0].children[0].kind).to eq(LSP::SymbolKind::FIELD)
      end

      it 'should find a variable assignment' do
        content = "$myvar = 'hello'"
        result = subject.extract_document_symbols(content)

        expect(result.count).to eq(1)
        expect(result[0].name).to eq('$myvar')
        expect(result[0].kind).to eq(LSP::SymbolKind::VARIABLE)
      end

      it 'should find resource attributes as children' do
        content = "user { 'alice':\n  ensure => present,\n}"
        result = subject.extract_document_symbols(content)

        expect(result.count).to eq(1)
        expect(result[0].children.count).to be >= 1
        ensure_sym = result[0].children.find { |c| c.name == 'ensure' }
        expect(ensure_sym).not_to be_nil
        expect(ensure_sym.kind).to eq(LSP::SymbolKind::VARIABLE)
      end
    end
  end
end
