require 'spec_debug_helper'

describe 'PuppetDebugServer::CommandLineParser' do
  describe '.parse' do
    it 'returns default options when no arguments given' do
      result = PuppetDebugServer::CommandLineParser.parse([])
      expect(result[:port]).to be_nil
      expect(result[:ipaddress]).to eq('localhost')
      expect(result[:stop_on_client_exit]).to be true
      expect(result[:connection_timeout]).to eq(10)
      expect(result[:debug]).to be_nil
      expect(result[:puppet_version]).to be_nil
    end

    it 'parses --port option' do
      result = PuppetDebugServer::CommandLineParser.parse(['--port=1234'])
      expect(result[:port]).to eq(1234)
    end

    it 'parses -p option for port' do
      result = PuppetDebugServer::CommandLineParser.parse(['-p', '4567'])
      expect(result[:port]).to eq(4567)
    end

    it 'parses --ip option' do
      result = PuppetDebugServer::CommandLineParser.parse(['--ip=0.0.0.0'])
      expect(result[:ipaddress]).to eq('0.0.0.0')
    end

    it 'parses --timeout option' do
      result = PuppetDebugServer::CommandLineParser.parse(['--timeout=30'])
      expect(result[:connection_timeout]).to eq(30)
    end

    it 'parses -t option for timeout' do
      result = PuppetDebugServer::CommandLineParser.parse(['-t', '0'])
      expect(result[:connection_timeout]).to eq(0)
    end

    it 'parses --debug option' do
      result = PuppetDebugServer::CommandLineParser.parse(['--debug=STDOUT'])
      expect(result[:debug]).to eq('STDOUT')
    end

    it 'parses --puppet-version option' do
      result = PuppetDebugServer::CommandLineParser.parse(['--puppet-version=5.4.0'])
      expect(result[:puppet_version]).to eq('5.4.0')
    end

    it 'does not mutate original options array' do
      options = ['--port=9999']
      original = options.dup
      PuppetDebugServer::CommandLineParser.parse(options)
      expect(options).to eq(original)
    end

    it 'returns a hash with all expected keys' do
      result = PuppetDebugServer::CommandLineParser.parse([])
      expect(result).to include(:port, :ipaddress, :stop_on_client_exit, :connection_timeout, :debug, :puppet_version)
    end
  end
end
