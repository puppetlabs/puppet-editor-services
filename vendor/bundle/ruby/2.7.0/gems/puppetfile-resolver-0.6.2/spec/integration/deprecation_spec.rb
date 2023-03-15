require 'spec_helper'

require 'puppetfile-resolver/resolver'
require 'puppetfile-resolver/puppetfile'


describe 'Depreaction Tests' do
  context 'With module_paths option' do
    it 'should resolve a complete Puppetfile' do

      content = <<-PUPFILE
      forge 'https://forge.puppet.com'

      # Local module path module
      mod 'testfixture/test_module', :latest
      PUPFILE

      puppetfile = ::PuppetfileResolver::Puppetfile::Parser::R10KEval.parse(content)
      resolver = PuppetfileResolver::Resolver.new(puppetfile)

      expect(Warning).to receive(:warn).with(/module_paths/).and_return(nil)

      result = resolver.resolve({
        allow_missing_modules: false,
        module_paths: [File.join(FIXTURES_DIR, 'modulepath')]
      })

      expect(result.specifications).to include('test_module')
      expect(result.specifications['test_module'].version.to_s).to eq('0.1.0')
    end
  end
end
