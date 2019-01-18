require 'spec_helper'

describe 'uri_helper' do
  let(:subject) { PuppetLanguageServer::UriHelper }

  describe '#build_file_uri' do
    it 'should return /// without leading slash' do
      test = subject.build_file_uri('C:\foo.pp')
      expect(test).to match('^file:///C')
    end
    it 'should return the uri escaped' do
      test = subject.build_file_uri('C:\foo.pp')
      expect(test).to eq('file:///C:%5Cfoo.pp')
    end
    it 'should return // with a leading slash' do
      test = subject.build_file_uri('/opt/foo/foo.pp')
      expect(test).to eq('file:///opt/foo/foo.pp')
    end
  end

  describe '#relative_uri_path' do
    it 'should return nil when the uri schemes differ' do
      expect(subject.relative_uri_path('file:///somewhere', 'http:///somewhere')).to be_nil
    end

    it 'should return nil if the uri is not a child of the root' do
      expect(subject.relative_uri_path('file:///somewhere', 'file:///foo/bar')).to be_nil
    end

    it 'should return nil if the uri is not a child of the root, when case sensitive' do
      expect(subject.relative_uri_path('file:///Foo/', 'file:///foo/bar')).to be_nil
    end

    it 'should unescape URIs when comparing' do
      expect(subject.relative_uri_path('file:///%66%6F%6F/', 'file:///foo/b%61r')).to eq('bar')
    end

    it 'should return the relative path if the uri is a child of the root' do
      expect(subject.relative_uri_path('file:///foo/', 'file:///foo/bar')).to eq('bar')
    end

    it 'should return the relative path if the uri is a child of the root and not case-sensitive' do
      expect(subject.relative_uri_path('file:///Foo/', 'file:///foo/bar', false)).to eq('bar')
    end
  end
end
