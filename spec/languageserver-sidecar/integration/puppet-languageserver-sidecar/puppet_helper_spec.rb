require 'spec_helper'

describe 'PuppetLanguageServerSidecar::PuppetHelper' do
  let (:subject) { PuppetLanguageServerSidecar::PuppetHelper }

  describe '#get_puppet_resource' do
    let (:typename) { 'user' }
    # This may do odd things with non ASCII usernames on Windows
    let (:title) { ENV['USER'] || ENV['USERNAME'] }

    context 'for a resource with no title' do
      it 'should return a deserializable resource list' do
        result = subject.get_puppet_resource(typename)

        expect(result.count).to be > 0
      end

      it 'should return a manifest with the current user for the user type' do
        result = subject.get_puppet_resource(typename)

        found = false
        result.each { |item| found = found || !(item.manifest =~ /#{title}/).nil? }
        expect(found).to be true
      end
    end

    context 'for a resource with a title' do
      it 'should return a deserializable resource list with a single result' do
        result = subject.get_puppet_resource(typename, title)

        expect(result.count).to eq(1)
      end

      it 'should return a manifest with the current user for the user type' do
        result = subject.get_puppet_resource(typename, title)

        found = false
        result.each { |item| found = found || !(item.manifest =~ /#{title}/).nil? }
        expect(found).to be true
      end
    end
  end
end
