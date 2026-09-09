require 'spec_helper'

describe 'PuppetLanguageServer' do
  before(:each) do
    allow(PuppetLanguageServer).to receive(:log_message)
  end

  describe '.featureflag?' do
    before(:each) { PuppetLanguageServer.configure_featureflags([]) }

    it 'returns false when flags are empty' do
      PuppetLanguageServer.configure_featureflags([])
      expect(PuppetLanguageServer.featureflag?(:some_flag)).to be false
    end

    it 'returns true when flag is included' do
      PuppetLanguageServer.configure_featureflags(['my_flag'])
      expect(PuppetLanguageServer.featureflag?('my_flag')).to be true
    end

    it 'returns false when flag is not present' do
      PuppetLanguageServer.configure_featureflags(['other_flag'])
      expect(PuppetLanguageServer.featureflag?('my_flag')).to be false
    end
  end

  describe 'CommandLineParser' do
    describe '.parse' do
      it 'returns default options with no arguments' do
        result = PuppetLanguageServer::CommandLineParser.parse([])
        expect(result[:ipaddress]).to eq('localhost')
        expect(result[:port]).to be_nil
        expect(result[:debug]).to be_nil
        expect(result[:flags]).to eq([])
        expect(result[:stdio]).to be false
        expect(result[:workspace]).to be_nil
      end

      it 'parses --port option' do
        result = PuppetLanguageServer::CommandLineParser.parse(['--port=1234'])
        expect(result[:port]).to eq(1234)
      end

      it 'parses -p short form for port' do
        result = PuppetLanguageServer::CommandLineParser.parse(['-p', '5678'])
        expect(result[:port]).to eq(5678)
      end

      it 'parses --ip option' do
        result = PuppetLanguageServer::CommandLineParser.parse(['--ip=0.0.0.0'])
        expect(result[:ipaddress]).to eq('0.0.0.0')
      end

      it 'parses --timeout option' do
        result = PuppetLanguageServer::CommandLineParser.parse(['--timeout=30'])
        expect(result[:connection_timeout]).to eq(30)
      end

      it 'parses --no-stop option' do
        result = PuppetLanguageServer::CommandLineParser.parse(['--no-stop'])
        expect(result[:stop_on_client_exit]).to be false
      end

      it 'parses --debug option' do
        result = PuppetLanguageServer::CommandLineParser.parse(['--debug=STDOUT'])
        expect(result[:debug]).to eq('STDOUT')
      end

      it 'parses --stdio option' do
        result = PuppetLanguageServer::CommandLineParser.parse(['--stdio'])
        expect(result[:stdio]).to be true
      end

      it 'parses --no-cache option' do
        result = PuppetLanguageServer::CommandLineParser.parse(['--no-cache'])
        expect(result[:disable_sidecar_cache]).to be true
      end

      it 'parses --cache option' do
        result = PuppetLanguageServer::CommandLineParser.parse(['--cache'])
        expect(result[:disable_sidecar_cache]).to be false
      end

      it 'parses --feature-flags option' do
        result = PuppetLanguageServer::CommandLineParser.parse(['--feature-flags=flag1,flag2'])
        expect(result[:flags]).to include('flag1', 'flag2')
      end

      it 'parses --puppet-settings option' do
        result = PuppetLanguageServer::CommandLineParser.parse(['--puppet-settings=--vardir,/tmp'])
        expect(result[:puppet_settings]).to include('--vardir')
      end

      it 'parses --puppet-version option' do
        result = PuppetLanguageServer::CommandLineParser.parse(['--puppet-version=5.4.0'])
        expect(result[:puppet_version]).to eq('5.4.0')
      end

      it 'does not mutate the input array' do
        options = ['--port=9999']
        original = options.dup
        PuppetLanguageServer::CommandLineParser.parse(options)
        expect(options).to eq(original)
      end
    end
  end
end
