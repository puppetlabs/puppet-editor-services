require 'spec_helper'

RSpec::Matchers.define :be_document_symbol do |name, kind, start_line, start_char, end_line, end_char|
  match do |actual|
    actual['name'] == name &&
    actual['kind'] == kind &&
    actual['range']['start']['line'] == start_line &&
    actual['range']['start']['character'] == start_char &&
    actual['range']['end']['line'] == end_line &&
    actual['range']['end']['character'] == end_char
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

describe 'PuppetLanguageServer::PuppetParserHelper' do
  let(:subject) { PuppetLanguageServer::PuppetParserHelper }

  describe '#extract_document_symbols' do
    it 'should find a class in the document root' do
      content = <<-EOT
      class foo {
      }
      EOT
      result = subject.extract_document_symbols(content)

      expect(result.count).to eq(1)
      expect(result[0]).to be_document_symbol('foo', LanguageServer::SYMBOLKIND_CLASS, 0, 6, 0, 9)
    end

    it 'should find a resource in the document root' do
      pending('Not supported yet')
      content = <<-EOT
      user { 'alice':
      }
      EOT
      result = subject.extract_document_symbols(content)

      expect(result.count).to eq(1)
      expect(result[0]).to be_document_symbol('alice', LanguageServer::SYMBOLKIND_MODULE, 0, 8, 0, 13)
    end

    it 'should find a single line class in the document root' do
      pending('Not supported yet')
      content = <<-EOT
      class foo(String $var1 = 'value1', String $var2 = 'value2') {
      }
      EOT
      result = subject.extract_document_symbols(content)

      expect(result.count).to eq(1)
      expect(result[0]).to be_document_symbol('foo', LanguageServer::SYMBOLKIND_CLASS, 0, 6, 0, 9)
      expect(result[0]['children'].count).to eq(2)
      # TODO: Check that the children are the properties var1 and var2
    end

    it 'should find a multi line class in the document root' do
      pending('Not supported yet')
      content = <<-EOT
      class foo(
        String $var1 = 'value1',
        String $var2 = 'value2',
      ) {
      }
      EOT
      result = subject.extract_document_symbols(content)

      expect(result.count).to eq(1)
      expect(result[0]).to be_document_symbol('foo', LanguageServer::SYMBOLKIND_CLASS, 0, 6, 0, 9)
      expect(result[0]['children'].count).to eq(2)
      # TODO: Check that the children are the properties var1 and var2
    end

    it 'should find a simple resource in a class' do
      content = <<-EOT
      class foo {
        user { 'alice':
        }
      }
      EOT
      result = subject.extract_document_symbols(content)

      expect(result.count).to eq(1)
      expect(result[0]).to be_document_symbol('foo', LanguageServer::SYMBOLKIND_CLASS, 0, 6, 0, 9)
      expect(result[0]['children'].count).to eq(1)
      expect(result[0]['children'][0]).to be_document_symbol('alice', LanguageServer::SYMBOLKIND_METHOD, 1, 8, 1, 13)
    end
  end

  # TODO: The method get_selection_range_array doesn't exist on the module
  # describe 'should find line' do
  #   it 'should find line of first class' do
  #     content      = "class wakka(\n  $param1 = ''\n) {\n  user { 'james':\n    ensure => 'present'\n  }\n}\n\nclass foo{\n}\n"
  #     line_offsets = [0, 13, 28, 32, 50, 74, 78, 80, 81, 92, 94]
  #     item_offset  = 0;
  #     item_name    = 'wakka'

  #     test = PuppetLanguageServer::PuppetParserHelper.get_selection_range_array(
  #       content,
  #       line_offsets,
  #       item_offset,
  #       item_name
  #     )

  #     expect(test).to be_a(Array)
  #     expect(test).to eq([0,6,0,11])

  #     item_offset  = 81;
  #     item_name    = 'foo'

  #     test = PuppetLanguageServer::PuppetParserHelper.get_selection_range_array(
  #       content,
  #       line_offsets,
  #       item_offset,
  #       item_name
  #     )

  #     expect(test).to be_a(Array)
  #     expect(test).to eq([9,6,9,9])

  #     # test_array = get_selection_range_array(content, line_offsets, item.offset, item.name)

  #   end
  # end
end
