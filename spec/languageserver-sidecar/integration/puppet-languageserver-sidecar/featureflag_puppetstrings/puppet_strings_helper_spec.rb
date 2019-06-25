require 'spec_helper'

describe 'PuppetLanguageServerSidecar with Feature Flag puppetstrings' do
  before(:each) do
    skip('Puppet Strings is not available') if Gem::Specification.select { |item| item.name.casecmp('puppet-strings') }.count.zero?
    skip('Puppet 6.0.0 or above is required') unless Gem::Version.new(Puppet.version) >= Gem::Version.new('6.0.0')

    # Load files based on feature flags
    ['puppet_strings_helper', 'puppet_strings_monkey_patches'].each do |lib|
      require "puppet-languageserver-sidecar/#{lib}"
    end
  end

  describe 'PuppetLanguageServerSidecar::PuppetStringsHelper' do
    let(:subject) { PuppetLanguageServerSidecar::PuppetStringsHelper::Helper.new }
    let(:cache) { nil }

    # Classes
    context 'Given a Puppet Class' do
      let(:fixture_filepath) { File.join($fixtures_dir, 'real_agent', 'environments', 'testfixtures', 'modules', 'defaultmodule', 'manifests', 'init.pp' ) }

      it 'should parse the file metadata correctly' do
        result = subject.file_documentation(fixture_filepath, cache)

        # There is only one class in the test fixture file
        expect(result.classes.count).to eq(1)
        item = result.classes[0]

        # Check base methods
        expect(item.key).to eq('defaultmodule')
        expect(item.line).to eq(8)
        expect(item.char).to be_nil
        expect(item.length).to be_nil
        expect(item.source).to eq(fixture_filepath)
        # Check class specific methods
        expect(item.doc).to match(/This is an example of how to document a Puppet class/)
        # Check the class parameters
        expect(item.parameters.count).to eq(2)
        param = item.parameters['first']
        expect(param[:doc]).to eq('The first parameter for this class.')
        expect(param[:type]).to eq('String')
        param = item.parameters['second']
        expect(param[:doc]).to eq('The second parameter for this class.')
        expect(param[:type]).to eq('Integer')
      end
    end

    context 'Given a Puppet Defined Type' do
      let(:fixture_filepath) { File.join($fixtures_dir, 'real_agent', 'environments', 'testfixtures', 'modules', 'defaultmodule', 'manifests', 'definedtype.pp' ) }

      it 'should parse the file metadata correctly' do
        result = subject.file_documentation(fixture_filepath, cache)

        # There is only one class in the test fixture file
        expect(result.classes.count).to eq(1)
        item = result.classes[0]

        # Check base methods
        expect(item.key).to eq('defaultdefinedtype')
        expect(item.line).to eq(6)
        expect(item.char).to be_nil
        expect(item.length).to be_nil
        expect(item.source).to eq(fixture_filepath)
        # Check class specific methods
        expect(item.doc).to match(/This is an example of how to document a defined type./)
        # Check the class parameters
        expect(item.parameters.count).to eq(2)
        param = item.parameters['ensure']
        expect(param[:doc]).to eq('Ensure parameter documentation.')
        expect(param[:type]).to eq('Any')
        param = item.parameters['param2']
        expect(param[:doc]).to eq('param2 documentation.')
        expect(param[:type]).to eq('String')
      end
    end

    # Functions
    context 'Given a Ruby Puppet 3 API Function' do
      let(:fixture_filepath) { File.join($fixtures_dir, 'real_agent', 'cache', 'lib', 'puppet', 'parser', 'functions', 'default_cache_function.rb' ) }

      it 'should parse the file metadata correctly' do
        result = subject.file_documentation(fixture_filepath, cache)

        # There is only one function in the test fixture file
        expect(result.functions.count).to eq(1)
        item = result.functions[0]

        # Check base methods
        expect(item.key).to eq('default_cache_function')
        expect(item.line).to eq(2)
        expect(item.char).to eq(12)
        expect(item.length).to eq(23)
        expect(item.source).to eq(fixture_filepath)
        # Check function specific methods
        expect(item.doc).to match(/A function that should appear in the list of default functions/)
        expect(item.function_version).to eq(3)
        # Check the function signatures
        expect(item.signatures.count).to eq(1)
        sig = item.signatures[0]
        expect(sig.doc).to match(/A function that should appear in the list of default functions/)
        expect(sig.key).to eq('default_cache_function()')
        expect(sig.return_types).to eq(['Any'])
        # Check the function signature parameters
        expect(sig.parameters.count).to eq(0)
      end
    end

    context 'Given a Ruby Puppet 4 API Function' do
      let(:fixture_filepath) { File.join($fixtures_dir, 'valid_module_workspace', 'lib', 'puppet', 'functions', 'fixture_pup4_function.rb') }

      it 'should parse the file metadata correctly' do
        result = subject.file_documentation(fixture_filepath, cache)

        # There is only one function in the test fixture file
        expect(result.functions.count).to eq(1)
        item = result.functions[0]
        # Check base methods
        expect(item.key).to eq('fixture_pup4_function')
        expect(item.line).to eq(3)
        expect(item.char).to eq(34)
        expect(item.length).to eq(22)
        expect(item.source).to eq(fixture_filepath)
        # Check function specific methods
        expect(item.doc).to match(/Example function using the Puppet 4 API in a module/)
        expect(item.function_version).to eq(4)
        # Check the function signatures
        expect(item.signatures.count).to eq(2)

        # First signature - No yard documentation
        sig = item.signatures[0]
        expect(sig.doc).to eq('')
        expect(sig.key).to eq('fixture_pup4_function(String $a_string, Optional[Callable] &$block)')
        expect(sig.return_types).to eq(['Array<String>'])
        # Check the function signature parameters
        expect(sig.parameters.count).to eq(2)
        sig_param = sig.parameters[0]
        expect(sig_param.name).to eq('a_string')
        expect(sig_param.doc).to eq('')
        expect(sig_param.types).to eq(['String'])
        expect(sig_param.signature_key_offset).to eq(29)
        expect(sig_param.signature_key_length).to eq(9)
        sig_param = sig.parameters[1]
        expect(sig_param.name).to eq('&block')
        expect(sig_param.doc).to eq('')
        expect(sig_param.types).to eq(['Optional[Callable]'])
        expect(sig_param.signature_key_offset).to eq(59)
        expect(sig_param.signature_key_length).to eq(7)

        # Second signature - Full yard documentation
        sig = item.signatures[1]
        expect(sig.doc).to eq('Does things with numbers')
        expect(sig.key).to eq('fixture_pup4_function(Integer $an_integer, Optional[Numeric] *$values_to_average)')
        expect(sig.return_types).to eq(['Array<String>'])
        # Check the function signature parameters
        expect(sig.parameters.count).to eq(2)
        sig_param = sig.parameters[0]
        expect(sig_param.name).to eq('an_integer')
        expect(sig_param.doc).to eq('The first number.')
        expect(sig_param.types).to eq(['Integer'])
        expect(sig_param.signature_key_offset).to eq(30)
        expect(sig_param.signature_key_length).to eq(11)
        sig_param = sig.parameters[1]
        expect(sig_param.name).to eq('*values_to_average')
        expect(sig_param.doc).to eq('Zero or more additional numbers.')
        expect(sig_param.types).to eq(['Optional[Numeric]'])
        expect(sig_param.signature_key_offset).to eq(61)
        expect(sig_param.signature_key_length).to eq(19)
      end
    end

    context 'Given a Puppet Language Function' do
      let(:fixture_filepath) { File.join($fixtures_dir, 'valid_module_workspace', 'functions', 'modulefunc.pp') }

      it 'should parse the file metadata correctly' do
        result = subject.file_documentation(fixture_filepath, cache)

        # There is only one function in the test fixture file
        expect(result.functions.count).to eq(1)
        item = result.functions[0]
        # Check base methods
        expect(item.key).to eq('valid::modulefunc')
        expect(item.line).to eq(7)
        expect(item.char).to be_nil
        expect(item.length).to be_nil
        expect(item.source).to eq(fixture_filepath)
        # Check function specific methods
        expect(item.doc).to match(/An example puppet function in a module, as opposed to a ruby custom function/)
        expect(item.function_version).to eq(4)
        # Check the function signatures
        expect(item.signatures.count).to eq(1)
        sig = item.signatures[0]
        expect(sig.doc).to match(/An example puppet function in a module, as opposed to a ruby custom function/)
        expect(sig.key).to eq('valid::modulefunc(Variant[String, Boolean] $p1)')
        expect(sig.return_types).to eq(['String'])
        # Check the function signature parameters
        expect(sig.parameters.count).to eq(1)
        sig_param = sig.parameters[0]
        expect(sig_param.name).to eq('p1')
        expect(sig_param.doc).to eq('The first parameter for this function.')
        expect(sig_param.types).to eq(['Variant[String, Boolean]'])
        expect(sig_param.signature_key_offset).to eq(43)
        expect(sig_param.signature_key_length).to eq(3)
      end
    end

    # Types
    context 'Given a Puppet Custom Type' do
      let(:fixture_filepath) { File.join($fixtures_dir, 'real_agent', 'cache', 'lib', 'puppet', 'type', 'default_type.rb' ) }

      it 'should parse the file metadata correctly' do
        result = subject.file_documentation(fixture_filepath, cache)

        # There is only one type in the test fixture file
        expect(result.types.count).to eq(1)
        item = result.types[0]

        # Check base methods
        expect(item.key).to eq('default_type')
        expect(item.line).to eq(1)
        expect(item.char).to be_nil
        expect(item.length).to be_nil
        expect(item.source).to eq(fixture_filepath)
        # Check type specific methods
        expect(item.doc).to match(/Sets the global defaults for all printers on the system./)
        # Check the type attributes
        expect(item.attributes.count).to eq(2)
        param = item.attributes['ensure']
        expect(param[:doc]).to eq('The basic property that the resource should be in.')
        expect(param[:type]).to eq(:property)
        expect(param[:isnamevar?]).to be_nil
        expect(param[:required?]).to be_nil
        param = item.attributes['name']
        expect(param[:doc]).to eq('The name of the default_type.')
        expect(param[:type]).to eq(:param)
        expect(param[:isnamevar?]).to eq(true)
        expect(param[:required?]).to be_nil
      end
    end
  end
end
