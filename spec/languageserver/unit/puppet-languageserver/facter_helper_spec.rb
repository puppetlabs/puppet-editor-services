require 'spec_helper'

describe 'PuppetLanguageServer::FacterHelper' do
  let(:cache) { PuppetLanguageServer::SessionState::ObjectCache.new }
  let(:session_state) { PuppetLanguageServer::ClientSessionState.new(nil, object_cache: cache, connection_id: 'test') }

  before(:each) do
    # Keys must be symbols so object_by_name (which interns string lookups) can find them
    cache.import_sidecar_list!([random_sidecar_fact(:os), random_sidecar_fact(:kernel)], :fact, :default)
  end

  describe '.fact' do
    it 'returns the fact object for a known fact' do
      result = PuppetLanguageServer::FacterHelper.fact(session_state, 'os')
      expect(result).not_to be_nil
      expect(result.key.to_s).to eq('os')
    end

    it 'returns nil for an unknown fact' do
      result = PuppetLanguageServer::FacterHelper.fact(session_state, 'no_such_fact')
      expect(result).to be_nil
    end
  end

  describe '.fact_value' do
    it 'returns the value for a known fact' do
      result = PuppetLanguageServer::FacterHelper.fact_value(session_state, 'os')
      expect(result).not_to be_nil
    end

    it 'returns nil for an unknown fact' do
      result = PuppetLanguageServer::FacterHelper.fact_value(session_state, 'no_such_fact')
      expect(result).to be_nil
    end
  end

  describe '.fact_names' do
    it 'returns the names of all known facts as strings' do
      result = PuppetLanguageServer::FacterHelper.fact_names(session_state)
      expect(result).to include('os', 'kernel')
    end
  end

  describe '.facts_to_hash' do
    it 'returns a hash of fact name to value' do
      result = PuppetLanguageServer::FacterHelper.facts_to_hash(session_state)
      expect(result).to be_a(Hash)
      expect(result.keys).to include('os', 'kernel')
    end
  end
end
