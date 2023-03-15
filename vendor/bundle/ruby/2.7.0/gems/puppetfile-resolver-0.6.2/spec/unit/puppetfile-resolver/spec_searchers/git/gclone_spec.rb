require 'spec_helper'
require 'puppetfile-resolver/spec_searchers/git/gclone'
require 'puppetfile-resolver/spec_searchers/git_configuration'
require 'logger'
require 'json'

describe PuppetfileResolver::SpecSearchers::Git::GClone do
  PuppetfileModule = Struct.new(:remote, :ref, :branch, :commit, :tag, keyword_init: true)
  config = PuppetfileResolver::SpecSearchers::GitConfiguration.new

  let(:url) do
    'https://github.com/puppetlabs/puppetlabs-powershell'
  end

  let(:puppetfile_module) do
    PuppetfileModule.new(remote: url)
  end


  context 'valid url' do
    it 'reads metadata' do
      content = subject.metadata(puppetfile_module, Logger.new(STDERR), config)
      expect(JSON.parse(content)['name']).to eq('puppetlabs-powershell')
    end

    context 'with tag' do
      let(:puppetfile_module) do
        PuppetfileModule.new(remote: url, ref: '2.1.2')
      end

      it 'reads metadata' do
        content = subject.metadata(puppetfile_module, Logger.new(STDERR), config)
        expect(JSON.parse(content)['name']).to eq('puppetlabs-powershell')
      end
    end

    context 'with commit' do
      let(:puppetfile_module) do
        PuppetfileModule.new(remote: url, ref: '9276de695798097e8471b877a18df27f764eecda')
      end

      it 'reads metadata' do
        content = subject.metadata(puppetfile_module, Logger.new(STDERR), config)
        expect(JSON.parse(content)['name']).to eq('puppetlabs-powershell')
      end
    end

    context 'with invalid ref' do
      let(:puppetfile_module) do
        PuppetfileModule.new(remote: url, ref: '8f7d5ea3ef49dadc5e166d5d802d091abc4b02bc')
      end

      it 'errors gracefully' do
        expect { subject.metadata(puppetfile_module, Logger.new(STDERR), config) }.to raise_error(
          /Could not find metadata\.json for ref .* at .*/
        )
      end
    end
  end

  context 'invalid url' do
    let(:url) do
      'https://user:password@github.com/puppetlabs/puppetlabs-powershellbad'
    end

    it 'throws exception' do
      expect{subject.metadata(puppetfile_module, Logger.new(STDERR), config)}
      .to raise_exception(RuntimeError)
    end
  end
end
