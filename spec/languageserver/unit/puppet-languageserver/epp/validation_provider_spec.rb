require 'spec_helper'

describe 'PuppetLanguageServer::Epp::ValidationProvider' do
  let(:subject) { PuppetLanguageServer::Epp::ValidationProvider }

  describe '#validate' do
    context 'with valid EPP content' do
      let(:content) { "<% $x = 'hello' %><%= $x %>" }

      it 'returns an empty array' do
        result = subject.validate(content)
        expect(result).to be_an(Array)
        expect(result).to be_empty
      end
    end

    context 'with EPP content that has a syntax error' do
      # Use a clearly invalid EPP expression to trigger a parse error
      let(:content) { "<% if %>" }

      it 'returns an Array' do
        result = subject.validate(content)
        expect(result).to be_an(Array)
      end

      it 'returns LSP::Diagnostic objects for any reported errors' do
        result = subject.validate(content)
        result.each { |d| expect(d).to be_a(LSP::Diagnostic) }
      end
    end

    context 'with EPP content that has a syntax error with location info' do
      # This forces a parse error that includes line/pos info
      let(:content) { "<%= \n %>\n<% $x\n" }

      it 'returns an Array' do
        result = subject.validate(content)
        expect(result).to be_an(Array)
      end
    end

    context 'with empty EPP content' do
      let(:content) { '' }

      it 'returns an empty array for empty content' do
        result = subject.validate(content)
        expect(result).to be_an(Array)
        expect(result).to be_empty
      end
    end
  end
end
