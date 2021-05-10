require 'spec_helper'

RSpec::Matchers.define :be_folding_range do |expected|
  match do |actual|
    expected.startLine == actual.startLine &&
    expected.startCharacter == actual.startCharacter &&
    expected.endLine == actual.endLine &&
    expected.endCharacter == actual.endCharacter &&
    expected.kind == actual.kind
  end

  failure_message do |actual|
    "expected that foldable range (#{actual.startLine}, #{actual.startCharacter}, #{actual.endLine}, #{actual.endCharacter}, #{actual.kind})" +
    " would be (#{expected.startLine}, #{expected.startCharacter}, #{expected.endLine}, #{expected.endCharacter}, #{expected.kind})"
  end

  description do
    "be a foldable range of (#{expected.startLine}, #{expected.startCharacter}, #{expected.endLine}, #{expected.endCharacter}, #{expected.kind})"
  end
end

def compare_range(this, that)
  # Initially look at the start line
  return -1 if this.startLine < that.startLine
  return 1 if this.startLine > that.startLine

  # They have the same start line so now consider the end line.
  # The biggest line range is sorted first
  return -1 if this.endLine > that.endLine
  return 1 if this.endLine < that.endLine

  # They have the same lines, but what about character offsets
  return -1 if this.startCharacter < that.startCharacter
  return 1 if this.startCharacter > that.startCharacter
  return -1 if this.endCharacter < that.endCharacter
  return 1 if this.endCharacter > that.endCharacter

  # They're the same range, but what about kind
  this.kind.to_s <=> that.kind.to_s
end

def lsp_range(item)
  LSP::FoldingRange.new({
    'startLine'      => item[0],
    'startCharacter' => item[1],
    'endLine'        => item[2],
    'endCharacter'   => item[3],
    'kind'           => item[4],
  })
end

describe 'PuppetLanguageServer::Manifest::FoldingProvider' do
  describe '::instance' do
    it 'should exist' do
      expect(PuppetLanguageServer::Manifest::FoldingProvider).to respond_to(:instance)
    end

    it 'should return the same object' do
      object1 = PuppetLanguageServer::Manifest::FoldingProvider.instance
      object2 = PuppetLanguageServer::Manifest::FoldingProvider.instance
      expect(object1).to eq(object2)
    end
  end

  describe '#folding_ranges', :unless => PuppetLanguageServer::Manifest::FoldingProvider.supported? do
    context 'when folding is not supported' do
      it 'returns nil' do
        subject = PuppetLanguageServer::Manifest::FoldingProvider.new
        expect(subject.folding_ranges([])).to be_nil
      end
    end
  end

  describe '#folding_ranges', :if => PuppetLanguageServer::Manifest::FoldingProvider.supported? do
    def expect_ranges(actual, expected)
      expect(actual.count).to eq(expected.count)

      # Sort the array to make it easier to assert equality
      actual.sort! { |this, that| compare_range(this, that) }

      actual.each_with_index do |actual_range, index|
        expect(actual_range).to be_folding_range(expected[index])
      end
    end

    context 'with all types of folding' do
      let(:doc_uri) { 'file://fakeuri.pp' }
      let(:doc_version) { 1 }
      let(:doc_store) do
        doc_store = PuppetLanguageServer::SessionState::DocumentStore.new
        doc_store.set_document(doc_uri, content, doc_version)
        doc_store
      end

      let(:content) do
<<-HEREDOC
# this won't be folded

# This block of comments should be foldable as a single block
# This block of comments should be foldable as a single block
# This block of comments should be foldable as a single block

#region This should fold
/*
Nested different comment types.  This should fold
*/
#endregion

# Comment Block 1
# Comment Block 1
# Comment Block 1
# region Comment Block 3
# Comment Block 2
# Comment Block 2
# Comment Block 2
# endregion Comment Block 3

class foldable {
  fail('boo')
}

class notfoldable {}

$non_folding_hash = { a => 3, b => 4 }

$folding_hash = {
  a => 3,
  b => 4,
}

$folding_array = [
  'abc',
  '123'
]

  file { 'C:\\something': # The line span fools the indentation based folding
    ensure => present,
    content => "Line
Span"
  }

#Region This should not fold due to casing on (R)egion
file { 'something': }
#Endregion

HEREDOC
      end

      let(:expected_ranges) do
        [
          lsp_range([2,  0,   4, 61,  'comment']),
          lsp_range([6,  0,  10, 10,  'region']),
          lsp_range([7,  0,   9,  2,  'comment']),
          lsp_range([12, 0,  14, 17,  'comment']),
          lsp_range([15, 0,  19, 27,  'region']),
          lsp_range([16, 0,  18, 17,  'comment']),
          lsp_range([21, 15, 23,  1,  nil]),
          lsp_range([29, 16, 32,  1,  nil]),
          lsp_range([34, 17, 37,  1,  nil]),
          lsp_range([39, 7,  43,  3,  nil])
        ]
      end

      it 'returns expected regions for LF endings' do
        subject = PuppetLanguageServer::Manifest::FoldingProvider.new
        expect(content).not_to include("\r\n")
        actual_ranges = subject.folding_ranges(doc_store.document_tokens(doc_uri, doc_version))
        expect_ranges(actual_ranges, expected_ranges)
      end

      it 'returns expected regions for CRLF endings' do
        subject = PuppetLanguageServer::Manifest::FoldingProvider.new
        content.gsub!("\n", "\r\n")
        actual_ranges = subject.folding_ranges(doc_store.document_tokens(doc_uri, doc_version))
        expect_ranges(actual_ranges, expected_ranges)
      end

      it 'returns expected regions when the Last Line is shown' do
        subject = PuppetLanguageServer::Manifest::FoldingProvider.new

        # When the last line is show it should reduce the end line by one and reset the end character to zero
        expected_ranges.each do |range|
          range.endLine = range.endLine - 1
          range.endCharacter = 0
        end

        actual_ranges = subject.folding_ranges(doc_store.document_tokens(doc_uri, doc_version), true)
        expect_ranges(actual_ranges, expected_ranges)
      end
    end

    context 'with mismatched regions' do
      let(:doc_uri) { 'file://fakeuri.pp' }
      let(:doc_version) { 1 }
      let(:doc_store) do
        doc_store = PuppetLanguageServer::SessionState::DocumentStore.new
        doc_store.set_document(doc_uri, content, doc_version)
        doc_store
      end

      let(:content) do
<<-HEREDOC
#endregion should not fold - mismatched

#region This should fold
$something = 'foldable'
#endregion

#region should not fold - mismatched
HEREDOC
      end

      let(:expected_ranges) do
        [
          lsp_range([2, 0, 4, 10, 'region']),
        ]
      end

      it 'returns only matched regions' do
        subject = PuppetLanguageServer::Manifest::FoldingProvider.new
        expect(content).not_to include("\r\n")
        actual_ranges = subject.folding_ranges(doc_store.document_tokens(doc_uri, doc_version))
        expect_ranges(actual_ranges, expected_ranges)
      end
    end

    context 'with duplicate regions on the same line' do
      let(:doc_uri) { 'file://fakeuri.pp' }
      let(:doc_version) { 1 }
      let(:doc_store) do
        doc_store = PuppetLanguageServer::SessionState::DocumentStore.new
        doc_store.set_document(doc_uri, content, doc_version)
        doc_store
      end

      let(:content) do
<<-HEREDOC
# This script causes duplicate/overlapping ranges due to the `[` and `{` characters
$var = [{
  'abc' => 123},{ 'xyz' => 234
  # Do Something
}]
HEREDOC
      end

      let(:expected_ranges) do
        [
          lsp_range([1, 7, 4, 2, nil]),
          lsp_range([2, 16, 4, 1, nil]),
        ]
      end

      it 'returns only matched regions' do
        subject = PuppetLanguageServer::Manifest::FoldingProvider.new
        expect(content).not_to include("\r\n")
        actual_ranges = subject.folding_ranges(doc_store.document_tokens(doc_uri, doc_version))
        expect_ranges(actual_ranges, expected_ranges)
      end
    end

    context 'with regions with the similar tokens' do
      let(:doc_uri) { 'file://fakeuri.pp' }
      let(:doc_version) { 1 }
      let(:doc_store) do
        doc_store = PuppetLanguageServer::SessionState::DocumentStore.new
        doc_store.set_document(doc_uri, content, doc_version)
        doc_store
      end

      # This tests that token matching { -> }, ?{ -> } and
      # [ -> ], @arr[ -> ]does not confuse the folder
      let(:content) do
<<-HEREDOC
class myclass($x = 10, $y = 20) {
  $ret = select ? {
    /abc/   => 123,
    default => 456
  }
}

$arr2 = [
  $arr1[
    0
  ]
]
HEREDOC
      end

      let(:expected_ranges) do
        [
          lsp_range([0, 32, 5, 1, nil]),
          lsp_range([1, 18, 4, 3, nil]),
          lsp_range([7, 8, 11, 1, nil]),
          lsp_range([8, 7, 10, 3, nil])
        ]
      end

      it 'returns only matched regions' do
        subject = PuppetLanguageServer::Manifest::FoldingProvider.new
        expect(content).not_to include("\r\n")
        actual_ranges = subject.folding_ranges(doc_store.document_tokens(doc_uri, doc_version))
        expect_ranges(actual_ranges, expected_ranges)
      end
    end

    context 'with regions inside different heredoc strings' do
      let(:doc_uri) { 'file://fakeuri.pp' }
      let(:doc_version) { 1 }
      let(:doc_store) do
        doc_store = PuppetLanguageServer::SessionState::DocumentStore.new
        doc_store.set_document(doc_uri, content, doc_version)
        doc_store
      end

      let(:content) do
<<-HEREDOC
$heredoc1 = @("SHORT"/L)
    [user]
      name = ${displayname}
      email = ${email}
    | SHORT

# The content is not interpolated so there is no folding
$heredoc2 = @(PUPDOCB/L)
    [user]
    name = ${[
      'abc',
      '123'
    ]}
    email = ${email}
| PUPDOCB

$heredoc3 = @("PUPDOCC"/L)
    [user]
        name = ${[
          'abc',
          '123'
        ]}
        email = ${email}
    | PUPDOCC

$heredoc4 = @("SOMETHING"/L)
    [user]
      name = ${name
        # Comment Block 1
        # Comment Block 1
        # Comment Block 1
      }
      email = ${email}
    | SOMETHING
HEREDOC
      end

      let(:expected_ranges) do
        [
          lsp_range([0,  12,  4, 0,  nil]),
          lsp_range([7,  12, 14, 0,  nil]),
          lsp_range([16, 12, 23, 0,  nil]),
          lsp_range([18, 17, 21, 9,  nil]),
          lsp_range([25, 12, 33, 0,  nil]),
          lsp_range([28,  8, 30, 25, 'comment']),
        ]
      end

      it 'returns only matched regions' do
        subject = PuppetLanguageServer::Manifest::FoldingProvider.new
        expect(content).not_to include("\r\n")
        actual_ranges = subject.folding_ranges(doc_store.document_tokens(doc_uri, doc_version))
        expect_ranges(actual_ranges, expected_ranges)
      end
    end

  end
end
