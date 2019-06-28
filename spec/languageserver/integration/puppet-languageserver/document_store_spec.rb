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

    it 'should not find environmentconf' do
      expect(PuppetLanguageServer::DocumentStore.store_has_environmentconf?).to be false
    end
  end

  RSpec.shared_examples 'a environmentconf workspace' do |expected_root_path|
    it 'should return the control repo root for the root_path' do
      expect(PuppetLanguageServer::DocumentStore.store_root_path).to eq(expected_root_path)
    end

    it 'should not find module metadata' do
      expect(PuppetLanguageServer::DocumentStore.store_has_module_metadata?).to be false
    end

    it 'should find environmentconf' do
      expect(PuppetLanguageServer::DocumentStore.store_has_environmentconf?).to be true
    end
  end

  RSpec.shared_examples 'a metadata.json workspace' do |expected_root_path|
    it 'should return the control repo root for the root_path' do
      expect(PuppetLanguageServer::DocumentStore.store_root_path).to eq(expected_root_path)
    end

    it 'should find module metadata' do
      expect(PuppetLanguageServer::DocumentStore.store_has_module_metadata?).to be true
    end

    it 'should not find environmentconf' do
      expect(PuppetLanguageServer::DocumentStore.store_has_environmentconf?).to be false
    end
  end

  RSpec.shared_examples 'a cached workspace' do
    it 'should cache the information' do
      expect(subject).to receive(:file_exist?).at_least(:once).and_call_original
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
      expect(subject).to receive(:file_exist?).at_least(:once).and_call_original
      result = PuppetLanguageServer::DocumentStore.store_root_path
      # Subsequent calls should be cached
      expect(subject).to receive(:file_exist?).exactly(0).times
      result = PuppetLanguageServer::DocumentStore.store_root_path
      result = PuppetLanguageServer::DocumentStore.store_root_path
      result = PuppetLanguageServer::DocumentStore.store_root_path
    end
  end

  RSpec.shared_examples 'a terminating file finder' do |expected_file_calls, expected_dir_calls|
    it 'should only traverse until it finds an expected file' do
      # TODO: This test is a little fragile but can't think of a better way to prove it
      expect(subject).to receive(:file_exist?).exactly(expected_file_calls).times.and_call_original
      expect(subject).to receive(:dir_exist?).exactly(expected_dir_calls).times.and_call_original
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

  # environmentconf style workspaces
  context 'given a workspace option with a environmentconf' do
    expected_root = File.join($fixtures_dir, 'control_repos', 'valid')

    let(:server_options) { { :workspace => expected_root } }

    before(:each) do
      PuppetLanguageServer::DocumentStore.initialize_store(server_options)
    end

    it_should_behave_like 'a environmentconf workspace', expected_root
    it_should_behave_like 'a cached workspace'
    it_should_behave_like 'a terminating file finder', 4, 1
  end

  context 'given a workspace option which has a parent directory with a environmentconf' do
    expected_root = File.join($fixtures_dir, 'control_repos', 'valid')
    deep_path = File.join(expected_root, 'site', 'profile')

    let(:server_options) { { :workspace => deep_path } }

    before(:each) do
      PuppetLanguageServer::DocumentStore.initialize_store(server_options)
    end

    it_should_behave_like 'a environmentconf workspace', expected_root
    it_should_behave_like 'a cached workspace'
    it_should_behave_like 'a terminating file finder', 8, 1
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
    it_should_behave_like 'a terminating file finder', 3, 1

    ['/plans/test.pp', '/plans/a/b/c/something.pp'].each do |testcase|
      it "should detect '#{testcase}' as a plan file" do
        file_uri = PuppetLanguageServer::UriHelper.build_file_uri(subject.store_root_path) + testcase
        expect(subject.plan_file?(file_uri)).to be(true)
      end
    end

    ['/plan__s/test.pp', 'plans/something.txt', '/plantest.pp', ].each do |testcase|
      it "should not detect '#{testcase}' as a plan file" do
        file_uri = PuppetLanguageServer::UriHelper.build_file_uri(subject.store_root_path) + testcase
        expect(subject.plan_file?(file_uri)).to be(false)
      end
    end

    it 'should detect plan files as case insensitive on Windows' do
      allow(subject).to receive(:windows?).and_return(true)
      file_uri = PuppetLanguageServer::UriHelper.build_file_uri(subject.store_root_path) + '/plans/test.pp'
      expect(subject.plan_file?(file_uri)).to be(true)
      file_uri = PuppetLanguageServer::UriHelper.build_file_uri(subject.store_root_path.upcase) + '/plans/test.pp'
      expect(subject.plan_file?(file_uri)).to be(true)
    end

    it 'should detect plan files as case sensitive not on Windows' do
      allow(subject).to receive(:windows?).and_return(false)
      file_uri = PuppetLanguageServer::UriHelper.build_file_uri(subject.store_root_path) + '/plans/test.pp'
      expect(subject.plan_file?(file_uri)).to be(true)
      file_uri = PuppetLanguageServer::UriHelper.build_file_uri(subject.store_root_path).upcase + '/plans/test.pp'
      expect(subject.plan_file?(file_uri.upcase)).to be(false)
    end
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
    it_should_behave_like 'a terminating file finder', 5, 1
  end
end
