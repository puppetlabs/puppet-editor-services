require 'spec_helper'
require 'open3'
require 'puppetfile-resolver/resolver'
require 'puppetfile-resolver/puppetfile'

describe 'Proxy Tests' do
  let(:content) do <<-PUPFILE
    forge 'https://forge.puppet.com'

    mod 'powershell',
      :git => 'https://github.com/puppetlabs/puppetlabs-powershell',
      :tag => 'v4.0.0'

    mod 'puppetlabs/stdlib', '6.3.0'
    PUPFILE
  end
  let(:puppetfile) { ::PuppetfileResolver::Puppetfile::Parser::R10KEval.parse(content) }
  let(:resolver_config) do
    PuppetfileResolver::SpecSearchers::Configuration.new.tap do |obj|
      obj.git.proxy = 'http://localhost:32768'
      obj.forge.proxy = 'http://localhost:32768'
    end
  end

  context 'with an invalid proxy server' do
    it 'should not resolve a complete Puppetfile' do
      resolver = PuppetfileResolver::Resolver.new(puppetfile)
      result = resolver.resolve({
        allow_missing_modules: true,
        spec_searcher_configuration: resolver_config,
      })

      expect(result.specifications).to include('powershell')
      expect(result.specifications['powershell']).to be_a(PuppetfileResolver::Models::MissingModuleSpecification)

      expect(result.specifications).to include('stdlib')
      expect(result.specifications['stdlib']).to be_a(PuppetfileResolver::Models::MissingModuleSpecification)
    end
  end

  context 'with a valid proxy server' do
    def start_proxy_server(start_options = ['--timeout=5'])
      cmd = "ruby \"#{File.join(FIXTURES_DIR, 'proxy.rb')}\" 32768"

      stdin, stdout, stderr, wait_thr = Open3.popen3(cmd)
      # Wait for the Proxy server to indicate it started
      line = nil
      begin
        line = stderr.readline
      end until line =~ /#start/
      stdout.close
      stdin.close
      [wait_thr, stderr]
    end

    before(:each) do
      @server_thr, @server_pipe = start_proxy_server
    end

    after(:each) do
      begin
        Process.kill("KILL", @server_thr[:pid])
        Process.wait(@server_thr[:pid])
      rescue
        # The server process may not exist and checking in a cross platform way in ruby is difficult
        # Instead just swallow any errors
      end

      begin
        @server_pipe.close
      rescue
        # The server process may not exist and checking in a cross platform way in ruby is difficult
        # Instead just swallow any errors
      end
    end

    it 'should resolve a complete Puppetfile' do
      resolver = PuppetfileResolver::Resolver.new(puppetfile)
      result = resolver.resolve({
        allow_missing_modules: false,
        spec_searcher_configuration: resolver_config,
      })

      expect(result.specifications).to include('powershell')
      expect(result.specifications['powershell'].version.to_s).to eq('4.0.0')

      expect(result.specifications).to include('stdlib')
      expect(result.specifications['stdlib'].version.to_s).to eq('6.3.0')
    end
  end
end
