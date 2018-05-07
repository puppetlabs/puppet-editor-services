require 'spec_helper'

describe 'PuppetLanguageServer::Epp::ValidationProvider' do
  let(:subject) { PuppetLanguageServer::Epp::ValidationProvider }

  describe '#validate' do
    describe "Given an EPP which has a syntax error" do
      let(:template) { '<%- String $tmp
      | -%>

      <%= $tmp %>' }

      it "should return a single syntax error" do
        result = subject.validate(template, nil)
        expect(result.length).to be > 0
        expect(result[0]['range']['start']['line']).to eq(1)
        expect(result[0]['range']['start']['character']).to eq(7)
        expect(result[0]['range']['end']['line']).to eq(1)
        expect(result[0]['range']['end']['character']).to eq(8)
      end
    end

    describe "Given a complete EPP which has no syntax errors" do
      let(:template) { '<%- | String $tmp
      | -%>

      <%= $tmp %>' }

      it "should return an empty array" do
        expect(subject.validate(template, nil)).to eq([])
      end
    end
  end
end
