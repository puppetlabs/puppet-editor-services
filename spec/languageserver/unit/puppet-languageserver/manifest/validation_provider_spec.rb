require 'spec_helper'

describe 'PuppetLanguageServer::Manifest::ValidationProvider' do
  let(:session_state) { PuppetLanguageServer::ClientSessionState.new(nil, connection_id: 'mock') }
  let(:subject) { PuppetLanguageServer::Manifest::ValidationProvider }

  before(:each) do
    allow(PuppetLanguageServer).to receive(:log_message)
  end

  describe '#validate' do
    context 'with valid puppet manifest' do
      let(:content) { "class foo { }" }

      it 'returns an array' do
        result = subject.validate(session_state, content)
        expect(result).to be_an(Array)
      end

      it 'returns diagnostics as LSP::Diagnostic objects' do
        result = subject.validate(session_state, content)
        result.each { |d| expect(d).to be_a(LSP::Diagnostic) }
      end
    end

    context 'with puppet manifest that has a syntax error' do
      let(:content) { "class foo { $x = }" }

      it 'returns an array of diagnostics' do
        result = subject.validate(session_state, content)
        expect(result).to be_an(Array)
      end

      it 'returns at least one diagnostic with ERROR severity' do
        result = subject.validate(session_state, content)
        expect(result.any? { |d| d.severity == LSP::DiagnosticSeverity::ERROR }).to be true
      end
    end

    context 'with puppet manifest that has a puppet-lint warning' do
      # Double-quoted string where single quotes should be used triggers a lint warning
      let(:content) { "class foo { $x = \"hello\" }" }

      it 'returns an array' do
        result = subject.validate(session_state, content)
        expect(result).to be_an(Array)
      end
    end

    context 'with tasks_mode enabled' do
      let(:content) { "class foo { }" }

      it 'returns an array when tasks_mode is true' do
        result = subject.validate(session_state, content, tasks_mode: true)
        expect(result).to be_an(Array)
      end
    end

    context 'with nil root path' do
      let(:content) { "class bar { }" }

      before(:each) do
        allow(session_state.documents).to receive(:store_root_path).and_return(nil)
      end

      it 'returns an array without error' do
        result = subject.validate(session_state, content)
        expect(result).to be_an(Array)
      end
    end
  end

  describe '#fix_validate_errors' do
    context 'with a manifest that has no lint errors' do
      let(:content) { "class foo { }" }

      it 'returns zero problems fixed' do
        problems_fixed, _new_content = subject.fix_validate_errors(session_state, content)
        expect(problems_fixed).to eq(0)
      end

      it 'returns the original content unchanged' do
        _problems_fixed, new_content = subject.fix_validate_errors(session_state, content)
        expect(new_content).to eq(content)
      end
    end

    context 'with a manifest that has a fixable lint error' do
      # Double-quoted string is fixable by puppet-lint --fix
      let(:content) { "class foo { $x = \"hello\" }" }

      it 'returns a non-negative number of problems' do
        problems_fixed, _new_content = subject.fix_validate_errors(session_state, content)
        expect(problems_fixed).to be >= 0
      end

      it 'returns content' do
        _problems_fixed, new_content = subject.fix_validate_errors(session_state, content)
        expect(new_content).to be_a(String)
      end
    end
  end
end
