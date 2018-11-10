require 'spec_helper'
require 'puppet_editor_services'

describe "version" do
  before :each do
    PuppetEditorServices.instance_eval do
      @editor_services_version = nil if @editor_services_version
    end
  end

  context "without a VERSION file" do
    before :each do
      expect(PuppetEditorServices).to receive(:read_version_file).and_return(nil)
    end

    it "is PuppetEditorServices::PUPPETEDITORSERVICESVERSION" do
      expect(PuppetEditorServices.version).to eq(PuppetEditorServices::PUPPETEDITORSERVICESVERSION)
    end
  end

  context "with a VERSION file" do
    let (:file_version) { '1.2.3' }

    before :each do
      expect(PuppetEditorServices).to receive(:read_version_file).with(/VERSION$/).and_return(file_version)
    end

    it "is the content of the file" do
      expect(PuppetEditorServices.version).to eq(file_version)
    end
  end
end
