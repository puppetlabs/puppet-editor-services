require 'spec_helper'

require 'puppetfile-resolver/resolver'
require 'puppetfile-resolver/puppetfile'

describe 'KitchenSink Tests' do
  it 'should resolve a complete Puppetfile' do
    content = <<-PUPFILE
    forge 'https://forge.puppet.com'

    mod 'powershell',
      :git => 'https://github.com/puppetlabs/puppetlabs-powershell',
      :tag => 'v4.0.0'

    mod 'simpkv',
      :git => 'https://gitlab.com/simp/pupmod-simp-simpkv.git',
      :tag => '0.7.1'

    mod 'puppetlabs/stdlib', '6.3.0'

    # Local module path module
    mod 'testfixture/test_module', :latest

    PUPFILE

    puppetfile = ::PuppetfileResolver::Puppetfile::Parser::R10KEval.parse(content)

    config = PuppetfileResolver::SpecSearchers::Configuration.new
    config.local.puppet_module_paths = [File.join(FIXTURES_DIR, 'modulepath')]

    resolver = PuppetfileResolver::Resolver.new(puppetfile)
    result = resolver.resolve({
      allow_missing_modules: false,
      spec_searcher_configuration: config,
    })

    expect(result.specifications).to include('powershell')
    expect(result.specifications['powershell'].version.to_s).to eq('4.0.0')

    expect(result.specifications).to include('simpkv')
    expect(result.specifications['simpkv'].version.to_s).to eq('0.7.1')

    expect(result.specifications).to include('stdlib')
    expect(result.specifications['stdlib'].version.to_s).to eq('6.3.0')

    expect(result.specifications).to include('test_module')
    expect(result.specifications['test_module'].version.to_s).to eq('0.1.0')
  end
end
