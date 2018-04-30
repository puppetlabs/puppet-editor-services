require 'spec_helper'

describe 'PuppetLanguageServer::PuppetHelper' do
  let(:subject) { PuppetLanguageServer::PuppetHelper }

  before(:all) { wait_for_puppet_loading }

  describe '#_load_default_classes' do
    # Note this is a private method, so this test can be a little brittle

    it 'should not error when the Puppet.setting[environmentpath] does not exist' do
      mocked_puppet_settings = Puppet.settings
      mocked_puppet_settings[:environmentpath] = 'dir/does/not/exist'

      expect(Puppet).to receive(:settings).and_return(mocked_puppet_settings).at_least(:once)

      result = subject.send :_load_default_classes
    end
  end
end
