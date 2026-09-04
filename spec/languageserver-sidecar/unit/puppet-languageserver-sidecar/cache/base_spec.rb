# frozen_string_literal: true

require 'spec_helper'
require 'puppet-languageserver-sidecar/cache/base'

describe 'PuppetLanguageServerSidecar::Cache::Base' do
  subject(:cache) { PuppetLanguageServerSidecar::Cache::Base.new }

  describe '#initialize' do
    it 'accepts an options hash' do
      cache_with_opts = PuppetLanguageServerSidecar::Cache::Base.new({ timeout: 60 })
      expect(cache_with_opts.cache_options).to eq({ timeout: 60 })
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
    it 'raises NotImplementedError' do
      expect { cache.load('/some/path', PuppetLanguageServerSidecar::Cache::CLASSES_SECTION) }
        .to raise_error(NotImplementedError)
    end
  end

  describe '#save' do
    it 'raises NotImplementedError' do
      expect { cache.save('/some/path', PuppetLanguageServerSidecar::Cache::FUNCTIONS_SECTION, 'content') }
        .to raise_error(NotImplementedError)
    end
  end

  describe '#clear!' do
    it 'raises NotImplementedError' do
      expect { cache.clear! }.to raise_error(NotImplementedError)
    end
  end

  describe 'cache section constants' do
    it 'defines a CLASSES_SECTION constant' do
      expect(PuppetLanguageServerSidecar::Cache::CLASSES_SECTION).to be_a(String)
    end

    it 'defines a FUNCTIONS_SECTION constant' do
      expect(PuppetLanguageServerSidecar::Cache::FUNCTIONS_SECTION).to be_a(String)
    end

    it 'defines a TYPES_SECTION constant' do
      expect(PuppetLanguageServerSidecar::Cache::TYPES_SECTION).to be_a(String)
    end

    it 'defines a PUPPETSTRINGS_SECTION constant' do
      expect(PuppetLanguageServerSidecar::Cache::PUPPETSTRINGS_SECTION).to be_a(String)
    end
  end
end
