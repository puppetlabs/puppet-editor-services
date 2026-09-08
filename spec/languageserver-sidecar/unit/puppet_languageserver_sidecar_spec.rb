require 'spec_helper'

describe 'PuppetLanguageServerSidecar' do
  before(:each) do
    allow(PuppetLanguageServerSidecar).to receive(:log_message)
  end

  describe '.featureflag?' do
    before(:each) do
      PuppetLanguageServerSidecar.configure_featureflags([])
    end

    it 'returns false when flags are empty' do
      PuppetLanguageServerSidecar.configure_featureflags([])
      expect(PuppetLanguageServerSidecar.featureflag?(:some_flag)).to be false
    end

    it 'returns true when flag is set' do
      PuppetLanguageServerSidecar.configure_featureflags(['my_flag'])
      expect(PuppetLanguageServerSidecar.featureflag?('my_flag')).to be true
    end

    it 'returns false when flag is not set' do
      PuppetLanguageServerSidecar.configure_featureflags(['other_flag'])
      expect(PuppetLanguageServerSidecar.featureflag?('my_flag')).to be false
    end
  end

  describe 'CommandLineParser' do
    describe '.parse' do
      it 'requires the action parameter' do
        expect { PuppetLanguageServerSidecar::CommandLineParser.parse([]) }.to raise_error(RuntimeError)
      end

      it 'parses --action option' do
        result = PuppetLanguageServerSidecar::CommandLineParser.parse(['--action', 'noop'])
        expect(result[:action]).to eq('noop')
      end

      it 'parses -a short form for action' do
        result = PuppetLanguageServerSidecar::CommandLineParser.parse(['-a', 'noop'])
        expect(result[:action]).to eq('noop')
      end

      it 'parses --local-workspace option' do
        result = PuppetLanguageServerSidecar::CommandLineParser.parse(['--action', 'noop', '--local-workspace=/tmp'])
        expect(result[:workspace]).to eq('/tmp')
      end

      it 'parses -w short form for workspace' do
        result = PuppetLanguageServerSidecar::CommandLineParser.parse(['-a', 'noop', '-w', '/tmp'])
        expect(result[:workspace]).to eq('/tmp')
      end

      it 'parses --output option' do
        result = PuppetLanguageServerSidecar::CommandLineParser.parse(['--action', 'noop', '--output=/tmp/out.json'])
        expect(result[:output]).to eq('/tmp/out.json')
      end

      it 'parses --puppet-version option' do
        result = PuppetLanguageServerSidecar::CommandLineParser.parse(['--action', 'noop', '--puppet-version=5.4.0'])
        expect(result[:puppet_version]).to eq('5.4.0')
      end

      it 'parses --feature-flags option' do
        result = PuppetLanguageServerSidecar::CommandLineParser.parse(['--action', 'noop', '--feature-flags=flag1,flag2'])
        expect(result[:flags]).to include('flag1', 'flag2')
      end

      it 'parses --no-cache option' do
        result = PuppetLanguageServerSidecar::CommandLineParser.parse(['--action', 'noop', '--no-cache'])
        expect(result[:disable_cache]).to be true
      end

      it 'parses --cache option (enables cache)' do
        result = PuppetLanguageServerSidecar::CommandLineParser.parse(['--action', 'noop', '--cache'])
        expect(result[:disable_cache]).to be false
      end

      it 'parses --debug option' do
        result = PuppetLanguageServerSidecar::CommandLineParser.parse(['--action', 'noop', '--debug=STDOUT'])
        expect(result[:debug]).to eq('STDOUT')
      end

      it 'parses --puppet-settings option' do
        result = PuppetLanguageServerSidecar::CommandLineParser.parse(['--action', 'noop', '--puppet-settings=--vardir,/tmp'])
        expect(result[:puppet_settings]).to include('--vardir')
      end

      it 'parses --action-parameters as JSON' do
        json = '{"key":"value"}'
        result = PuppetLanguageServerSidecar::CommandLineParser.parse(['--action', 'noop', "--action-parameters=#{json}"])
        expect(result[:action_parameters]).to respond_to(:to_json)
      end

      it 'raises on invalid JSON action-parameters' do
        expect {
          PuppetLanguageServerSidecar::CommandLineParser.parse(['--action', 'noop', '--action-parameters=not_json'])
        }.to raise_error(RuntimeError, /Unable to parse the action parameters/)
      end

      it 'sets defaults for unspecified options' do
        result = PuppetLanguageServerSidecar::CommandLineParser.parse(['--action', 'noop'])
        expect(result[:debug]).to be_nil
        expect(result[:disable_cache]).to be false
        expect(result[:flags]).to eq([])
        expect(result[:workspace]).to be_nil
      end
    end
  end
end
