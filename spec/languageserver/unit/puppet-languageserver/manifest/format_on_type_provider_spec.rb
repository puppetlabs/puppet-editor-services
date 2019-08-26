require 'spec_helper'

describe 'PuppetLanguageServer::Manifest::FormatOnTypeProvider' do
  let(:subject) { PuppetLanguageServer::Manifest::FormatOnTypeProvider.new }

  describe '::instance' do
    it 'should exist' do
      expect(PuppetLanguageServer::Manifest::FormatOnTypeProvider).to respond_to(:instance)
    end

    it 'should return the same object' do
      object1 = PuppetLanguageServer::Manifest::FormatOnTypeProvider.instance
      object2 = PuppetLanguageServer::Manifest::FormatOnTypeProvider.instance
      expect(object1).to eq(object2)
    end
  end

  describe '#format' do
    let(:formatting_options) do
      LSP::FormattingOptions.new.tap do |item|
        item.tabSize = 2
        item.insertSpaces = true
      end.to_h
    end

    [' ', '=', ','].each do |trigger|
      context "given a trigger character of '#{trigger}'" do
        it 'should return an empty array' do
          result = subject.format("{\n  oneline    =>\n}\n", 1, 1, trigger, formatting_options)
          expect(result).to eq([])
        end
      end
    end

    context "given a trigger character of greater-than '>'" do
      let(:trigger_character) { '>' }
      let(:content) do <<-MANIFEST
user {
  ensure=> 'something',
  password   =>
  name => {
    'abc' => '123',
    'def'    => '789',
  },
  name2    => 'correct',
}
MANIFEST
      end
      let(:valid_cursor) { { line: 2, char: 15 } }
      let(:inside_cursor) { { line: 5, char: 15 } }

      it 'should return an empty array if the cursor is not on a hashrocket' do
        result = subject.format(content, 1, 1, trigger_character, formatting_options)
        expect(result).to eq([])
      end

      it 'should return an empty array if the formatting options uses tabs' do
        result = subject.format(content, valid_cursor[:line], valid_cursor[:char], trigger_character, formatting_options.tap { |i| i['insertSpaces'] = false} )
        expect(result).to eq([])
      end

      it 'should return an empty array if the document is large' do
        large_content = content + ' ' * 4096
        result = subject.format(large_content, valid_cursor[:line], valid_cursor[:char], trigger_character, formatting_options)
        expect(result).to eq([])
      end

      # Valid hashrocket key tests
      [
        { name: 'bare name',            text: 'barename' },
        { name: 'single quoted string', text: '\'name\'' },
        { name: 'double quoted string', text: '"name"' },
      ].each do |testcase|
        context "and given a manifest with #{testcase[:name]}" do
          let(:content) { "{\n  a =>\n  ##TESTCASE## => 'value'\n}\n"}

          it 'should return an empty' do
            result = subject.format(content.gsub('##TESTCASE##', testcase[:text]), 1, 6, trigger_character, formatting_options)
            # The expected TextEdit should edit the `a =>`
            expect(result.count).to eq(1)
            expect(result[0].range.start.line).to eq(1)
            expect(result[0].range.start.character).to eq(3)
            expect(result[0].range.end.line).to eq(1)
            expect(result[0].range.end.character).to eq(4)
          end
        end
      end

      it 'should have valid text edits in the outer hash' do
        result = subject.format(content, valid_cursor[:line], valid_cursor[:char], trigger_character, formatting_options)

        expect(result.count).to eq(3)
        expect(result[0].to_h).to eq({"range"=>{"start"=>{"character"=>8,  "line"=>1}, "end"=>{"character"=>8,  "line"=>1}}, "newText"=>"   "})
        expect(result[1].to_h).to eq({"range"=>{"start"=>{"character"=>10, "line"=>2}, "end"=>{"character"=>13, "line"=>2}}, "newText"=>" "})
        expect(result[2].to_h).to eq({"range"=>{"start"=>{"character"=>6,  "line"=>3}, "end"=>{"character"=>7,  "line"=>3}}, "newText"=>"     "})
      end

      it 'should have valid text edits in the inner hash' do
        result = subject.format(content, inside_cursor[:line], inside_cursor[:char], trigger_character, formatting_options)

        expect(result.count).to eq(1)
        expect(result[0].to_h).to eq({"range"=>{"start"=>{"character"=>9, "line"=>5}, "end"=>{"character"=>13, "line"=>5}}, "newText"=>" "})
      end

      # Invalid scenarios
      [
        { name: 'only one line',                      content: "{\n  oneline    =>\n}\n" },
        { name: 'there is nothing to indent',         content: "{\n  oneline    =>\n  nextline12 => 'value',\n}\n" },
        { name: 'no starting Left Brace',             content: "\n  oneline    =>\n  nextline12 => 'value',\n}\n" },
        { name: 'no ending Right Brace',              content: "{\n  oneline    =>\n  nextline12 => 'value',\n\n" },
        { name: 'hashrockets on the same line',       content: "{\n  oneline    => ,  nextline12 => 'value',\n\n"},
        { name: 'invalid text before the hashrocket', content: "{\n  String[]   =>\n  nextline => 'value',\n}\n" },
      ].each do |testcase|
        context "and given a manifest with #{testcase[:name]}" do
          it 'should return an empty' do
            result = subject.format(testcase[:content], 1, 15, trigger_character, formatting_options)
            expect(result).to eq([])
          end
        end
      end
    end
  end
end
