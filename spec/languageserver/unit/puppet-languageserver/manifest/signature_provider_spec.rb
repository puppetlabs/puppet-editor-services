require 'spec_helper'

describe 'PuppetLanguageServer::Manifest::SignatureProvider' do
  let(:session_state) { PuppetLanguageServer::ClientSessionState.new(nil, connection_id: 'mock') }
  let(:subject) { PuppetLanguageServer::Manifest::SignatureProvider }

  before(:each) do
    populate_cache(session_state.object_cache)
    allow(PuppetLanguageServer).to receive(:log_message)
  end

  describe '#signature_help' do
    context 'when cursor is in whitespace (object_under_cursor returns nil)' do
      let(:content) { "# just a comment\n\n" }

      it 'returns an empty SignatureHelp' do
        result = subject.signature_help(session_state, content, 1, 0)
        expect(result).to be_a(LSP::SignatureHelp)
        expect(result.signatures).to be_empty
      end
    end

    context 'when cursor is inside a known function call' do
      # `notice` is a built-in puppet function
      let(:content) { "notice('hello')\n" }
      # position cursor inside the parens after the function name
      let(:line_num) { 0 }
      let(:char_num) { 8 }

      it 'returns a SignatureHelp without raising' do
        expect { subject.signature_help(session_state, content, line_num, char_num) }.not_to raise_error
      end

      it 'returns a LSP::SignatureHelp object' do
        result = subject.signature_help(session_state, content, line_num, char_num)
        expect(result).to be_a(LSP::SignatureHelp)
      end
    end

    context 'with tasks_mode enabled' do
      let(:content) { "notice('hello')\n" }

      it 'returns a SignatureHelp without raising' do
        expect { subject.signature_help(session_state, content, 0, 8, tasks_mode: true) }.not_to raise_error
      end
    end

    context 'when cursor is directly on the function call node (between arguments)' do
      # In notice('hello', 'world'), at the space/comma between args the only AST node
      # that spans that position is the CallNamedFunctionExpression itself (not any argument)
      let(:content) { "notice('hello', 'world')\n" }

      it 'returns a SignatureHelp without raising' do
        # Position 15 is between the two string arguments (after comma, before 'world')
        expect { subject.signature_help(session_state, content, 0, 15) }.not_to raise_error
      end

      it 'returns a LSP::SignatureHelp object' do
        result = subject.signature_help(session_state, content, 0, 15)
        expect(result).to be_a(LSP::SignatureHelp)
      end
    end

    context 'when cursor is after the last argument' do
      # Position cursor after 'world' but before closing ) — exercises the
      # char_offset > last_offset branch in param_number_from_ast
      let(:content) { "notice('hello', 'world'  )\n" }

      it 'returns a SignatureHelp without raising' do
        # Position 25 is after 'world' and before ) with extra spaces
        expect { subject.signature_help(session_state, content, 0, 25) }.not_to raise_error
      end

      it 'returns a LSP::SignatureHelp object' do
        result = subject.signature_help(session_state, content, 0, 25)
        expect(result).to be_a(LSP::SignatureHelp)
      end
    end
  end
end
