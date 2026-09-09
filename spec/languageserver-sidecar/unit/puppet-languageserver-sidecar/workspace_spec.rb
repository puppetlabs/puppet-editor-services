require 'spec_helper'
require 'tmpdir'

describe 'PuppetLanguageServerSidecar::Workspace' do
  let(:subject) { PuppetLanguageServerSidecar::Workspace }

  describe '.detect_workspace' do
    it 'sets root_path based on the given path' do
      Dir.mktmpdir do |dir|
        subject.detect_workspace(dir)
        expect(subject.root_path).not_to be_nil
      end
    end
  end

  describe '.has_module_metadata?' do
    it 'returns true when metadata.json exists in the detected workspace' do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'metadata.json'), '{}')
        subject.detect_workspace(dir)
        expect(subject.has_module_metadata?).to be true
      end
    end

    it 'returns false when no metadata.json exists' do
      Dir.mktmpdir do |dir|
        subject.detect_workspace(dir)
        expect(subject.has_module_metadata?).to be false
      end
    end
  end

  describe '.has_environmentconf?' do
    it 'returns true when environment.conf exists in the detected workspace' do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'environment.conf'), '')
        subject.detect_workspace(dir)
        expect(subject.has_environmentconf?).to be true
      end
    end

    it 'returns false when no environment.conf exists' do
      Dir.mktmpdir do |dir|
        subject.detect_workspace(dir)
        expect(subject.has_environmentconf?).to be false
      end
    end
  end

  describe '.detect_workspace with nil path' do
    it 'does not raise an error' do
      expect { subject.detect_workspace(nil) }.not_to raise_error
    end

    it 'sets root_path to nil when path is nil' do
      subject.detect_workspace(nil)
      expect(subject.root_path).to be_nil
    end
  end

  describe '.detect_workspace with a file path' do
    it 'finds the containing directory' do
      Dir.mktmpdir do |dir|
        file = File.join(dir, 'test.pp')
        File.write(file, 'class test {}')
        subject.detect_workspace(file)
        expect(subject.root_path).not_to be_nil
      end
    end
  end

  describe '.detect_workspace with metadata.json in parent directory' do
    it 'walks up to find the metadata.json root' do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, 'metadata.json'), '{}')
        subdir = File.join(dir, 'manifests')
        Dir.mkdir(subdir)
        subject.detect_workspace(subdir)
        expect(subject.root_path).to eq(dir)
        expect(subject.has_module_metadata?).to be true
      end
    end
  end

  describe '.detect_workspace with a non-existent path' do
    it 'sets root_path to the given path when not found on disk' do
      subject.detect_workspace('/no/such/path/at/all')
      expect(subject.root_path).to eq('/no/such/path/at/all')
    end
  end
end
