require 'spec_helper'

describe 'server_capabilites' do
  describe '#capabilities' do
    it 'should return a hash' do
      expect(PuppetLanguageServer::ServerCapabilites.capabilities).to be_a(Hash)
    end

    it 'should not have an onTypeFormattingProvider by default' do
      expect(PuppetLanguageServer::ServerCapabilites.capabilities[:documentOnTypeFormattingProvider]).to be_nil
    end

    context 'with the hashrocket feature flag set' do
      before(:each) do
        allow(PuppetLanguageServer).to receive(:featureflag?).with('hashrocket').and_return(true)
      end

      it 'should have a onTypeFormattingProvider' do
        expect(PuppetLanguageServer::ServerCapabilites.capabilities[:documentOnTypeFormattingProvider]).to eq({ 'firstTriggerCharacter' => '>' })
      end
    end
  end
end
