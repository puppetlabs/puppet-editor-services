require 'spec_helper'

describe 'PuppetLanguageServer::Manifest::DefinitionProvider' do
  let(:session_state) { PuppetLanguageServer::ClientSessionState.new(nil, connection_id: 'mock') }
  let(:subject) { PuppetLanguageServer::Manifest::DefinitionProvider }

  before(:each) do
    populate_cache(session_state.object_cache)
    allow(PuppetLanguageServer).to receive(:log_message)
  end

  describe '#find_definition' do
    context 'when cursor is on whitespace (no AST object)' do
      let(:content) { "# just a comment\n\n" }

      it 'returns nil' do
        result = subject.find_definition(session_state, content, 1, 0)
        expect(result).to be_nil
      end
    end

    context 'when cursor is on a function call' do
      let(:content) { "notice('hello')\n" }

      it 'returns an array without raising' do
        expect { subject.find_definition(session_state, content, 0, 2) }.not_to raise_error
      end

      it 'returns an Array' do
        result = subject.find_definition(session_state, content, 0, 2)
        expect(result).to be_an(Array)
      end
    end

    context 'when cursor is on a resource expression type name' do
      let(:content) { "user { 'bob':\n  ensure => present,\n}\n" }

      it 'returns an Array without raising' do
        expect { subject.find_definition(session_state, content, 0, 2) }.not_to raise_error
      end
    end

    context 'when cursor is on a resource class reference (LiteralString in ResourceBody)' do
      let(:content) { "class { 'foo':\n}\n" }

      it 'returns an Array without raising' do
        expect { subject.find_definition(session_state, content, 0, 9) }.not_to raise_error
      end
    end

    context 'with tasks_mode enabled' do
      let(:content) { "notice('hello')\n" }

      it 'returns without raising' do
        expect { subject.find_definition(session_state, content, 0, 2, tasks_mode: true) }.not_to raise_error
      end
    end
  end
end
