require 'spec_helper'

describe 'PuppetLanguageServerSidecar::PuppetHelper', :if => Gem::Version.new(Puppet.version) >= Gem::Version.new('5.0.0') do
  let(:subject) { PuppetLanguageServerSidecar::PuppetHelper }
  let(:cache) { PuppetLanguageServerSidecar::Cache::Null.new }

  describe '#retrieve_classes' do
    # Note this is a private method, so this test can be a little brittle

    it 'should not error when the Puppet.setting[environmentpath] does not exist' do
      mocked_puppet_settings = Puppet.settings
      mocked_puppet_settings[:environmentpath] = 'dir/does/not/exist'

      expect(Puppet).to receive(:settings).and_return(mocked_puppet_settings).at_least(:once)

      result = subject.send(:retrieve_via_puppet_strings, cache, { object_types: [:class] })
    end
  end
end
