require 'spec_helper'

describe 'PuppetLanguageServer::DocumentStore' do
  let(:subject) { PuppetLanguageServer::DocumentStore }

  RSpec.shared_examples 'an empty workspace' do |expected_root_path|
    it 'should return the workspace directory for the root_path' do
      expect(PuppetLanguageServer::DocumentStore.store_root_path).to eq(expected_root_path)
    end

    it 'should not find module metadata' do
      expect(PuppetLanguageServer::DocumentStore.store_has_module_metadata?).to be false
    end

    it 'should not find puppetfile' do
      expect(PuppetLanguageServer::DocumentStore.store_has_puppetfile?).to be false
    end
  end

  RSpec.shared_examples 'a puppetfile workspace' do |expected_root_path|
    it 'should return the control repo root for the root_path' do
      expect(PuppetLanguageServer::DocumentStore.store_root_path).to eq(expected_root_path)
    end

    it 'should not find module metadata' do
      expect(PuppetLanguageServer::DocumentStore.store_has_module_metadata?).to be false
    end

    it 'should find puppetfile' do
      expect(PuppetLanguageServer::DocumentStore.store_has_puppetfile?).to be true
    end
  end

  RSpec.shared_examples 'a metadata.json workspace' do |expected_root_path|
    it 'should return the control repo root for the root_path' do
      expect(PuppetLanguageServer::DocumentStore.store_root_path).to eq(expected_root_path)
    end

    it 'should find module metadata' do
      expect(PuppetLanguageServer::DocumentStore.store_has_module_metadata?).to be true
    end

    it 'should not find puppetfile' do
      expect(PuppetLanguageServer::DocumentStore.store_has_puppetfile?).to be false
    end
  end

  RSpec.shared_examples 'a cached workspace' do
    it 'should cache the information' do
      expect(subject).to receive(:file_exist?).at_least(:once)
      result = PuppetLanguageServer::DocumentStore.store_root_path
      # Subsequent calls should be cached
      expect(subject).to receive(:file_exist?).exactly(0).times
      result = PuppetLanguageServer::DocumentStore.store_root_path
      result = PuppetLanguageServer::DocumentStore.store_root_path
      result = PuppetLanguageServer::DocumentStore.store_root_path
    end

    it 'should recache the information when the cache expires' do
      result = PuppetLanguageServer::DocumentStore.store_root_path
      # Expire the cache
      PuppetLanguageServer::DocumentStore.expire_store_information
      expect(subject).to receive(:file_exist?).at_least(:once)
      result = PuppetLanguageServer::DocumentStore.store_root_path
      # Subsequent calls should be cached
      expect(subject).to receive(:file_exist?).exactly(0).times
      result = PuppetLanguageServer::DocumentStore.store_root_path
      result = PuppetLanguageServer::DocumentStore.store_root_path
      result = PuppetLanguageServer::DocumentStore.store_root_path
    end
  end

  # Empty or missing workspace
  context 'given a workspace option which is nil' do
    let(:server_options) { {} }

    before(:each) do
      PuppetLanguageServer::DocumentStore.initialize_store(server_options)
    end

    it_should_behave_like 'an empty workspace', nil

    it 'should cache the information' do
      expect(subject).to receive(:file_exist?).exactly(0).times
      result = PuppetLanguageServer::DocumentStore.store_root_path
      result = PuppetLanguageServer::DocumentStore.store_root_path
      result = PuppetLanguageServer::DocumentStore.store_root_path
      result = PuppetLanguageServer::DocumentStore.store_root_path
    end

    it 'should not recache the information when the cache expires' do
      expect(subject).to receive(:file_exist?).exactly(0).times
      result = PuppetLanguageServer::DocumentStore.store_root_path
      PuppetLanguageServer::DocumentStore.expire_store_information
      result = PuppetLanguageServer::DocumentStore.store_root_path
      result = PuppetLanguageServer::DocumentStore.store_root_path
      result = PuppetLanguageServer::DocumentStore.store_root_path
      result = PuppetLanguageServer::DocumentStore.store_root_path
    end
  end

  context 'given a workspace option with a missing directory' do
    let(:server_options) { { :workspace => '/a/directory/which/does/not/exist' } }

    before(:each) do
      PuppetLanguageServer::DocumentStore.initialize_store(server_options)
    end

    it_should_behave_like 'an empty workspace', '/a/directory/which/does/not/exist'
  end

  # Puppetfile style workspaces
  context 'given a workspace option with a puppetfile' do
    expected_root = File.join($fixtures_dir, 'control_repos', 'valid')

    let(:server_options) { { :workspace => expected_root } }

    before(:each) do
      PuppetLanguageServer::DocumentStore.initialize_store(server_options)
    end

    it_should_behave_like 'a puppetfile workspace', expected_root
    it_should_behave_like 'a cached workspace'
  end

  context 'given a workspace option which has a parent directory with a puppetfile' do
    expected_root = File.join($fixtures_dir, 'control_repos', 'valid')
    deep_path = File.join(expected_root, 'site', 'profile')

    let(:server_options) { { :workspace => deep_path } }

    before(:each) do
      PuppetLanguageServer::DocumentStore.initialize_store(server_options)
    end

    it_should_behave_like 'a puppetfile workspace', expected_root
    it_should_behave_like 'a cached workspace'
  end

  # Module metadata style workspaces
  context 'given a workspace option with metadata.json' do
    expected_root = File.join($fixtures_dir, 'module_sources', 'valid')

    let(:server_options) { { :workspace => expected_root } }

    before(:each) do
      PuppetLanguageServer::DocumentStore.initialize_store(server_options)
    end

    it_should_behave_like 'a metadata.json workspace', expected_root
    it_should_behave_like 'a cached workspace'
  end

  context 'given a workspace option which has a parent directory with metadata.json' do
    expected_root = File.join($fixtures_dir, 'module_sources', 'valid')
    deep_path = File.join(expected_root, 'manifests')

    let(:server_options) { { :workspace => deep_path } }

    before(:each) do
      PuppetLanguageServer::DocumentStore.initialize_store(server_options)
    end

    it_should_behave_like 'a metadata.json workspace', expected_root
    it_should_behave_like 'a cached workspace'
  end
end
