# frozen_string_literal: true

require 'spec_helper'
require 'puppet-languageserver-sidecar/cache/base'
require 'puppet-languageserver-sidecar/cache/null'

describe 'PuppetLanguageServerSidecar::Cache::Null' do
  subject(:cache) { PuppetLanguageServerSidecar::Cache::Null.new }

  it 'is a subclass of Cache::Base' do
    expect(cache).to be_a(PuppetLanguageServerSidecar::Cache::Base)
  end

  describe '#initialize' do
    it 'accepts an options hash' do
      cache_with_opts = PuppetLanguageServerSidecar::Cache::Null.new({ timeout: 30 })
      expect(cache_with_opts.cache_options).to eq({ timeout: 30 })
    end

    it 'defaults to an empty options hash' do
      expect(cache.cache_options).to eq({})
    end
  end

  describe '#active?' do
    it 'returns false' do
      expect(cache.active?).to be(false)
    end
  end

  describe '#load' do
    it 'returns nil for any path and section' do
      result = cache.load('/some/path', PuppetLanguageServerSidecar::Cache::CLASSES_SECTION)
      expect(result).to be_nil
    end

    it 'accepts any number of arguments' do
      expect { cache.load('/path', 'section', 'extra') }.not_to raise_error
    end
  end

  describe '#save' do
    it 'returns true for any arguments' do
      result = cache.save('/some/path', PuppetLanguageServerSidecar::Cache::FUNCTIONS_SECTION, 'content')
      expect(result).to be(true)
    end

    it 'accepts any number of arguments' do
      expect { cache.save('/path', 'section', 'data', 'extra') }.not_to raise_error
    end
  end

  describe '#clear!' do
    it 'returns nil' do
      expect(cache.clear!).to be_nil
    end

    it 'does not raise' do
      expect { cache.clear! }.not_to raise_error
    end
  end
end
