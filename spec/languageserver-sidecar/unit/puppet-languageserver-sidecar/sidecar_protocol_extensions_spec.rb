require 'spec_helper'

describe 'PuppetLanguageServerSidecar::Protocol' do
  describe 'NodeGraph' do
    let(:subject_klass) { PuppetLanguageServerSidecar::Protocol::PuppetNodeGraph }
    let(:subject) { subject_klass.new }

    it "instance should respond to set_error" do
      expect(subject).to respond_to(:set_error)
      result = subject.set_error('test_error')
      expect(result.vertices).to eq(nil)
      expect(result.edges).to eq(nil)
      expect(result.error_content).to eq('test_error')
    end
  end
end
