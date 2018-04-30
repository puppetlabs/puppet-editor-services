require 'spec_helper'

describe 'PuppetLanguageServer::PuppetHelper::PersistentFileCache' do
  let(:subject) { PuppetLanguageServer::PuppetHelper::PersistentFileCache.new(nil, {}) }

  describe '#initialize' do
    it 'should use Dir.tmpdir to detect cache directory' do
      expect(Dir).to receive(:tmpdir).and_call_original

      subject
    end

    context 'when cache directory cannot be created' do
      before(:each) do
        expect(Dir).to receive(:tmpdir).and_return('/dir/does/not/exist')
      end

      it 'should disable cache if cache dir is unable to be created' do
        subject

        expect(subject.cache_disabled?).to be true
      end

      it 'should return nil for loading files' do
        expect(subject.load('anyfile', 'a_key')).to be_nil
      end

      it 'should return false for saving files' do
        expect(subject.save!('anyfile', 'a_key')).to be false
      end
    end
  end
end
