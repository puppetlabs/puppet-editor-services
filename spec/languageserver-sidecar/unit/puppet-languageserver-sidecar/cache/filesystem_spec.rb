require 'spec_helper'
require 'tmpdir'

describe 'PuppetLanguageServerSidecar::Cache::FileSystem' do
  let(:subject) { PuppetLanguageServerSidecar::Cache::FileSystem.new({}) }

  before(:each) do
    allow(PuppetLanguageServerSidecar).to receive(:log_message)
  end

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

        expect(subject.active?).to be false
      end

      it 'should return nil for loading files' do
        expect(subject.load('anyfile', 'a_section')).to be_nil
      end

      it 'should return false for saving files' do
        expect(subject.save('anyfile', 'a_section', 'a_content')).to be false
      end
    end
  end

  describe '#active?' do
    it 'returns true when cache directory was created' do
      expect(subject.active?).to be true
    end
  end

  describe '#save and #load' do
    it 'saves content to the cache and loads it back' do
      Dir.mktmpdir do |dir|
        # Create a real file to cache
        source_file = File.join(dir, 'test.pp')
        File.write(source_file, 'class foo {}')

        content = 'cached content string'
        subject.save(source_file, 'functions', content)
        result = subject.load(source_file, 'functions')
        expect(result).to eq(content)
      end
    end

    it 'returns nil when loading a file that has not been cached' do
      Dir.mktmpdir do |dir|
        source_file = File.join(dir, 'unknown.pp')
        File.write(source_file, 'class foo {}')
        result = subject.load(source_file, 'functions')
        expect(result).to be_nil
      end
    end

    it 'returns nil when the cached file content has changed' do
      Dir.mktmpdir do |dir|
        source_file = File.join(dir, 'test.pp')
        File.write(source_file, 'class foo {}')

        subject.save(source_file, 'functions', 'cached content')
        # Change the file content
        File.write(source_file, 'class bar {}')
        result = subject.load(source_file, 'functions')
        expect(result).to be_nil
      end
    end
  end

  describe '#clear!' do
    it 'does not raise when active' do
      expect { subject.clear! }.not_to raise_error
    end

    it 'removes cached files' do
      Dir.mktmpdir do |dir|
        source_file = File.join(dir, 'test.pp')
        File.write(source_file, 'class foo {}')

        subject.save(source_file, 'functions', 'data')
        subject.clear!
        result = subject.load(source_file, 'functions')
        expect(result).to be_nil
      end
    end
  end
end
