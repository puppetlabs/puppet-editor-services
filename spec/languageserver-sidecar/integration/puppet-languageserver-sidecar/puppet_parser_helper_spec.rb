require 'spec_helper'

describe 'PuppetLanguageServerSidecar::PuppetParserHelper' do
  let (:subject) { PuppetLanguageServerSidecar::PuppetParserHelper }

  describe '#compile_node_graph' do
    def tasks_supported?
      Gem::Version.new(Puppet.version) >= Gem::Version.new('5.4.0')
    end

    before(:each) do
      @original_taskmode = Puppet[:tasks] if tasks_supported?
      Puppet[:tasks] = false if tasks_supported?
    end

    after(:each) do
      Puppet[:tasks] = @original_taskmode if tasks_supported?
    end

    context 'a valid manifest' do
      let(:manifest) { "user { 'test':\nensure => present\n}\n "}

      it 'should compile succesfully' do
        result = subject.compile_node_graph(manifest)
        expect(result).to_not be_nil

        # Make sure it's a DOT graph file
        expect(result.dot_content).to match(/digraph/)
        # Make sure the resource is there
        expect(result.dot_content).to match(/User\[test\]/)
        # Make sure the fontsize is set to empty
        expect(result.dot_content).to match(/fontsize = \"\"/)
        # Make sure the label is editorservices
        expect(result.dot_content).to match(/label = \"editorservices\"/)
        # Expect no errors
        expect(result.error_content.to_s).to eq('')
      end
    end

    context 'a valid manifest with no resources' do
      let(:manifest) { "" }

      it 'should compile with an error' do
        result = subject.compile_node_graph(manifest)
        expect(result).to_not be_nil
        expect(result.dot_content).to eq("")
        expect(result.error_content).to match(/no resources created in the node graph/)
      end
    end

    context 'an invalid manifest' do
      let(:manifest) { "I am an invalid manifest" }

      it 'should compile with an error' do
        result = subject.compile_node_graph(manifest)
        expect(result).to_not be_nil
        expect(result.dot_content).to eq("")
        expect(result.error_content).to match(/Error while parsing the file./)
      end
    end
  end
end
