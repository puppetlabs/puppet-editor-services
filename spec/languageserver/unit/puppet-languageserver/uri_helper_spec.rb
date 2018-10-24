require 'spec_helper'

describe 'uri_helper' do
  describe '#build_file_uri' do
    it 'should return /// without leading slash' do
      test = PuppetLanguageServer::UriHelper.build_file_uri('C:\foo.pp')
      expect(test).to eq('file:///C:\foo.pp')
    end
    it 'should return // with a leading slash' do
      test = PuppetLanguageServer::UriHelper.build_file_uri('/opt/foo/foo.pp')
      expect(test).to eq('file:///opt/foo/foo.pp')
    end
  end
end
