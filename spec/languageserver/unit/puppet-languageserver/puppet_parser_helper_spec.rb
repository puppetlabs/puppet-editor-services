require 'spec_helper'

describe 'PuppetLanguageServer::PuppetParserHelper' do
  let(:subject) { PuppetLanguageServer::PuppetParserHelper }

  describe '#line_offsets' do
    it 'returns [0] for content with no newlines' do
      expect(subject.line_offsets('hello world')).to eq([0])
    end

    it 'returns correct offsets for multi-line content' do
      # "hello\nworld\n" → line 0 at 0, line 1 at 6, line 2 at 12
      result = subject.line_offsets("hello\nworld\n")
      expect(result).to eq([0, 6, 12])
    end

    it 'returns [0] for empty string' do
      expect(subject.line_offsets('')).to eq([0])
    end

    it 'handles multiple newlines' do
      result = subject.line_offsets("a\nb\nc")
      expect(result).to eq([0, 2, 4])
    end
  end

  describe '#get_line_at' do
    let(:content) { "first line\nsecond line\nthird" }
    let(:offsets) { subject.line_offsets(content) }

    it 'returns the text of the first line' do
      expect(subject.get_line_at(content, offsets, 0)).to eq('first line')
    end

    it 'returns the text of the second line' do
      expect(subject.get_line_at(content, offsets, 1)).to eq('second line')
    end

    it 'returns text for the last line (no trailing newline)' do
      # Line 2 is "third" with no next offset
      result = subject.get_line_at(content, offsets, 2)
      expect(result).to include('third')
    end
  end

  describe '#get_char_at' do
    let(:content) { "hello\nworld\n" }
    let(:offsets) { subject.line_offsets(content) }

    it 'returns the character at the given line and position' do
      # line 0, char 1 → offset 0+0 = 0, content[0] = 'h'... wait
      # get_char_at uses char_num-1 as offset
      # line_offset = offsets[0] = 0
      # absolute_offset = 0 + (2 - 1) = 1 → 'e'
      expect(subject.get_char_at(content, offsets, 0, 2)).to eq('e')
    end

    it 'returns character from second line' do
      # line 1 starts at offset 6 ("world\n")
      # char 1 → absolute = 6 + (1-1) = 6 → 'w'
      expect(subject.get_char_at(content, offsets, 1, 1)).to eq('w')
    end
  end

  describe '#insert_text_at' do
    let(:content) { "hello world\n" }
    let(:offsets) { subject.line_offsets(content) }

    it 'inserts text at the given position' do
      result = subject.insert_text_at(content, offsets, 0, 5, ' there')
      expect(result).to include('hello there')
    end

    it 'returns a String' do
      result = subject.insert_text_at(content, offsets, 0, 0, 'X')
      expect(result).to be_a(String)
    end
  end

  describe '#remove_char_at' do
    let(:content) { "hello world\n" }
    let(:offsets) { subject.line_offsets(content) }

    it 'removes the character at the given position' do
      # At line 0, char 1: remove_chars_starting_at(..., 1, 1)
      # slice(0, 0 + 1 - 1) + slice(0 + 1, ...) = '' + 'hello world\n'[1..] = 'ello world\n'
      result = subject.remove_char_at(content, offsets, 0, 1)
      expect(result).to be_a(String)
      expect(result.length).to eq(content.length - 1)
    end
  end

  describe '#object_under_cursor' do
    before(:each) do
      allow(PuppetLanguageServer).to receive(:log_message)
    end

    context 'with simple manifest content' do
      let(:content) { "notice('hello')\n" }

      it 'returns a result hash for valid content' do
        result = subject.object_under_cursor(content, 0, 8, {})
        expect(result).not_to be_nil
      end

      it 'returns nil when cursor is in whitespace' do
        result = subject.object_under_cursor("\n\n", 1, 0, {})
        expect(result).to be_nil
      end
    end

    context 'with multiple_attempts: true' do
      it 'does not raise for valid content' do
        content = "notice('hello')\n"
        expect { subject.object_under_cursor(content, 0, 8, multiple_attempts: true) }.not_to raise_error
      end

      it 'handles content needing multiple attempts' do
        # Content with a trigger character scenario
        content = "$x = \n"
        result = subject.object_under_cursor(content, 0, 5, multiple_attempts: true, remove_trigger_char: false)
        # Should not raise; result may be nil for root-level incomplete expression
        expect { result }.not_to raise_error
      end
    end

    context 'with tasks_mode' do
      it 'does not raise with tasks_mode enabled' do
        content = "notice('hello')\n"
        expect { subject.object_under_cursor(content, 0, 8, tasks_mode: true) }.not_to raise_error
      end
    end
  end
end
