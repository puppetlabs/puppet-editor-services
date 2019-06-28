require 'spec_helper'

describe 'PuppetLanguageServer::DocumentStore' do
  let(:subject) { PuppetLanguageServer::DocumentStore }

  describe '#module_plan_file?' do
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
            expect(subject.module_plan_file?(file_uri)).to be(true)
          end
        end
      end

      it 'should detect plan files in a case insensitive way when on Windows' do
        allow(subject).to receive(:windows?).and_return(true)
        file_uri = plan_files[0]
        expect(subject.module_plan_file?(file_uri)).to be(true)
        expect(subject.module_plan_file?(file_uri.upcase)).to be(true)
      end

      it 'should detect plan files in a case sensitive way when not on Windows' do
        allow(subject).to receive(:windows?).and_return(false)
        file_uri = plan_files[0]
        expect(subject.module_plan_file?(file_uri)).to be(true)
        expect(subject.module_plan_file?(file_uri.upcase)).to be(false)
      end
    end

    context 'for files which are not plans' do
      not_plan_files.each do |testcase|
        prefixes.each do |prefix|
          it "should not detect '#{prefix}#{testcase}' as a plan file" do
            file_uri = PuppetLanguageServer::UriHelper.build_file_uri(prefix + testcase)
            expect(subject.module_plan_file?(file_uri)).to be(false)
          end
        end
      end

      it 'should detect plan files in a case insensitive way when on Windows' do
        allow(subject).to receive(:windows?).and_return(true)
        file_uri = not_plan_files[0]
        expect(subject.module_plan_file?(file_uri)).to be(false)
        expect(subject.module_plan_file?(file_uri.upcase)).to be(false)
      end

      it 'should detect plan files in a case sensitive way when not on Windows' do
        allow(subject).to receive(:windows?).and_return(false)
        file_uri = not_plan_files[0]
        expect(subject.module_plan_file?(file_uri)).to be(false)
        expect(subject.module_plan_file?(file_uri.upcase)).to be(false)
      end
    end
  end
end
