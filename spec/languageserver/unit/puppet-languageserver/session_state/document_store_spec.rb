require 'spec_helper'

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
