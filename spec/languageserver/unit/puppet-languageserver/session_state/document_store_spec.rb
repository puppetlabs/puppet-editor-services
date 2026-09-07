require 'spec_helper'
require 'tmpdir'

describe 'PuppetLanguageServer::SessionState::DocumentStore' do
  let(:subject) { PuppetLanguageServer::SessionState::DocumentStore.new }

  describe '#set_document' do
    let(:content) { 'content' }
    let(:version) { 1 }
    [
      { :name => 'n EPP document', :uri => '/template.epp', :klass => PuppetLanguageServer::SessionState::EppDocument },
      { :name => ' Puppet Manifest', :uri => '/manifest.pp', :klass => PuppetLanguageServer::SessionState::ManifestDocument },
      { :name => ' Puppetfile', :uri => '/Puppetfile', :klass => PuppetLanguageServer::SessionState::PuppetfileDocument },
      { :name => 'n unknown document', :uri => '/unknown.txt', :klass => PuppetLanguageServer::SessionState::Document },
    ].each do |testcase|
      it "creates a #{testcase[:klass]} object for a#{testcase[:name]}" do
        subject.set_document(testcase[:uri], content, version)
        expect(subject.document(testcase[:uri], version)).to be_a(testcase[:klass])
      end
    end

    it 'updates an existing document with new content' do
      uri = 'file://test.pp'
      subject.set_document(uri, 'original', 1)
      subject.set_document(uri, 'updated', 2)
      expect(subject.document(uri, 2).content).to eq('updated')
    end
  end

  describe '#remove_document' do
    let(:uri) { 'file://test.pp' }

    before(:each) { subject.set_document(uri, 'content', 1) }

    it 'removes the document' do
      subject.remove_document(uri)
      expect(subject.document(uri)).to be_nil
    end

    it 'returns nil' do
      expect(subject.remove_document(uri)).to be_nil
    end
  end

  describe '#clear' do
    it 'removes all documents' do
      subject.set_document('file://a.pp', 'content', 1)
      subject.set_document('file://b.pp', 'content', 1)
      subject.clear
      expect(subject.document('file://a.pp')).to be_nil
      expect(subject.document('file://b.pp')).to be_nil
    end
  end

  describe '#document_content' do
    let(:uri) { 'file://test.pp' }

    before(:each) { subject.set_document(uri, 'hello world', 1) }

    it 'returns the content for an existing document' do
      expect(subject.document_content(uri)).to eq('hello world')
    end

    it 'returns nil for a non-existent uri' do
      expect(subject.document_content('file://missing.pp')).to be_nil
    end

    it 'returns nil for wrong version' do
      expect(subject.document_content(uri, 99)).to be_nil
    end

    it 'returns a clone (not the same object)' do
      original = subject.document(uri).content
      expect(subject.document_content(uri).object_id).not_to eq(original.object_id)
    end
  end

  describe '#get_document' do
    let(:uri) { 'file://test.pp' }

    before(:each) { subject.set_document(uri, 'content here', 1) }

    it 'returns the content for an existing document' do
      expect(subject.get_document(uri)).to eq('content here')
    end

    it 'returns nil for a non-existent document' do
      expect(subject.get_document('file://missing.pp')).to be_nil
    end
  end

  describe '#document_version' do
    let(:uri) { 'file://test.pp' }

    before(:each) { subject.set_document(uri, 'content', 42) }

    it 'returns the version of the document' do
      expect(subject.document_version(uri)).to eq(42)
    end

    it 'returns nil for non-existent document' do
      expect(subject.document_version('file://missing.pp')).to be_nil
    end
  end

  describe '#document_uris' do
    it 'returns an empty array when no documents exist' do
      expect(subject.document_uris).to eq([])
    end

    it 'returns all stored document URIs' do
      subject.set_document('file://a.pp', 'content', 1)
      subject.set_document('file://b.pp', 'content', 1)
      uris = subject.document_uris
      expect(uris).to include('file://a.pp', 'file://b.pp')
    end
  end

  describe '#document_type' do
    it 'returns :manifest for .pp files' do
      expect(subject.document_type('file:///path/to/manifest.pp')).to eq(:manifest)
    end

    it 'returns :epp for .epp files' do
      expect(subject.document_type('file:///path/to/template.epp')).to eq(:epp)
    end

    it 'returns :puppetfile for Puppetfile' do
      expect(subject.document_type('file:///path/to/Puppetfile')).to eq(:puppetfile)
    end

    it 'returns :unknown for other files' do
      expect(subject.document_type('file:///path/to/readme.txt')).to eq(:unknown)
    end
  end

  describe '#store_root_path' do
    context 'with no workspace configured' do
      it 'returns nil' do
        expect(subject.store_root_path).to be_nil
      end
    end

    context 'with a non-existent workspace path' do
      before(:each) do
        subject.initialize_store(workspace: '/this/path/should/never/exist')
      end

      it 'returns the workspace path' do
        result = subject.store_root_path
        expect(result).to eq('/this/path/should/never/exist')
      end
    end

    context 'with an existing workspace directory' do
      let(:tmpdir) { Dir.mktmpdir }
      after(:each) { FileUtils.rm_rf(tmpdir) }

      it 'returns a path' do
        subject.initialize_store(workspace: tmpdir)
        expect(subject.store_root_path).not_to be_nil
      end

      context 'that contains a metadata.json file' do
        before(:each) do
          File.write(File.join(tmpdir, 'metadata.json'), '{}')
          subject.initialize_store(workspace: tmpdir)
        end

        it 'detects module metadata' do
          expect(subject.store_has_module_metadata?).to be true
        end
      end

      context 'that contains an environment.conf file' do
        before(:each) do
          File.write(File.join(tmpdir, 'environment.conf'), '')
          subject.initialize_store(workspace: tmpdir)
        end

        it 'detects environment config' do
          expect(subject.store_has_environmentconf?).to be true
        end
      end
    end
  end

  describe '#expire_store_information' do
    it 'does not raise' do
      expect { subject.expire_store_information }.not_to raise_error
    end
  end

  describe '#plan_file?' do
    before(:each) do
      # Assume we are not in any module or control repo. Just a bare file
      allow(subject).to receive(:store_has_module_metadata?).and_return(false)
      allow(subject).to receive(:store_has_environmentconf?).and_return(false)
    end

    plan_files = [
      'project/Boltdir/site-modules/project/plans/manifests/init.pp',
      'plans/test.pp',
      'plans/a/b/c/something.pp',
      'project/Boltdir/site-modules/project/plans/foo/bar/wizz/diagnose.pp',
      'something/plans/foo/bar/wizz/diagnose.pp'
    ]

    not_plan_files = [
      'project/Boltdir/site-modules/project/manifests/plans/init.pp',
      'something/plan__s/test.pp',
      'plantest.pp',
      'project/Boltdir/site-modules/project/manifests/init.pp'
    ]

    prefixes = ['/', 'C:/']

    context 'for files which are plans' do
      plan_files.each do |testcase|
        prefixes.each do |prefix|
          it "should detect '#{prefix}#{testcase}' as a plan file" do
            file_uri = PuppetLanguageServer::UriHelper.build_file_uri(prefix + testcase)

            expect(subject.plan_file?(file_uri)).to be(true)
          end
        end
      end

      it 'should detect plan files in a case insensitive way when on Windows' do
        allow(subject).to receive(:windows?).and_return(true)
        file_uri = plan_files[0]
        expect(subject.plan_file?(file_uri)).to be(true)
        expect(subject.plan_file?(file_uri.upcase)).to be(true)
      end

      it 'should detect plan files in a case sensitive way when not on Windows' do
        allow(subject).to receive(:windows?).and_return(false)
        file_uri = plan_files[0]
        expect(subject.plan_file?(file_uri)).to be(true)
        expect(subject.plan_file?(file_uri.upcase)).to be(false)
      end
    end

    context 'for files which are not plans' do
      not_plan_files.each do |testcase|
        prefixes.each do |prefix|
          it "should not detect '#{prefix}#{testcase}' as a plan file" do
            file_uri = PuppetLanguageServer::UriHelper.build_file_uri(prefix + testcase)
            expect(subject.plan_file?(file_uri)).to be(false)
          end
        end
      end

      it 'should detect plan files in a case insensitive way when on Windows' do
        allow(subject).to receive(:windows?).and_return(true)
        file_uri = not_plan_files[0]
        expect(subject.plan_file?(file_uri)).to be(false)
        expect(subject.plan_file?(file_uri.upcase)).to be(false)
      end

      it 'should detect plan files in a case sensitive way when not on Windows' do
        allow(subject).to receive(:windows?).and_return(false)
        file_uri = not_plan_files[0]
        expect(subject.plan_file?(file_uri)).to be(false)
        expect(subject.plan_file?(file_uri.upcase)).to be(false)
      end
    end
  end

  describe '#document_tokens' do
    let(:uri) { 'file://something.pp' }
    let(:content) { 'content' }
    let(:version) { 1 }

    before(:each) do
      subject.set_document(uri, content, version)
    end

    it 'returns nil for documents that do not exist' do
      expect(subject.document_tokens('file://bad_uri', version)).to be_nil
    end

    it 'returns nil for document versions that do not exist' do
      expect(subject.document_tokens(uri, -1)).to be_nil
    end

    it 'returns tokens for latest document version' do
      expect(subject.document_tokens(uri)).to_not be_nil
    end

    it 'caches the document tokens for the same version of the file' do
      first = subject.document_tokens(uri)
      second = subject.document_tokens(uri)
      expect(first.object_id).to eq(second.object_id)
    end

    it 'recalculates document tokens when the file changes' do
      first = subject.document_tokens(uri)
      subject.set_document(uri, content, version + 1)
      second = subject.document_tokens(uri)
      expect(first.object_id).to_not eq(second.object_id)
    end
  end
end
