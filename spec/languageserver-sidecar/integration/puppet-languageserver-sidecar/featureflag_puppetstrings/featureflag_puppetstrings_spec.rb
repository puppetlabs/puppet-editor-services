require 'spec_helper'
require 'open3'
require 'tempfile'

describe 'PuppetLanguageServerSidecar with Feature Flag puppetstrings', :if => Gem::Version.new(Puppet.version) >= Gem::Version.new('6.0.0') do
  def run_sidecar(cmd_options)
    # Use a new array so we don't affect the original cmd_options)
    cmd = cmd_options.dup
    # Append the feature flag
    cmd << '--feature-flag=puppetstrings'

    # Append the puppet test-fixtures
    cmd << '--puppet-settings'
    cmd << "--vardir,#{File.join($fixtures_dir, 'real_agent', 'cache')},--confdir,#{File.join($fixtures_dir, 'real_agent', 'confdir')}"

    cmd.unshift('puppet-languageserver-sidecar')
    cmd.unshift('ruby')
    stdout, _stderr, status = Open3.capture3(*cmd)

    raise "Expected exit code of 0, but got #{status.exitstatus} #{_stderr}" unless status.exitstatus.zero?
    return stdout.bytes.pack('U*')
  end

  def child_with_key(array, key)
    idx = array.index { |item| item.key == key }
    return idx.nil? ? nil : array[idx]
  end

  def with_temporary_file(content)
    tempfile = Tempfile.new("langserver-sidecar")
    tempfile.open

    tempfile.write(content)

    tempfile.close

    yield tempfile.path
  ensure
    tempfile.delete if tempfile
  end

  RSpec::Matchers.define :contain_child_with_key do |key|
    match do |actual|
      !(actual.index { |item| item.key == key }).nil?
    end

    failure_message do |actual|
      "expected that #{actual.class.to_s} would contain a child with key #{key}"
    end
  end

  def should_not_contain_default_functions(deserial)
    # These functions should not appear in the deserialised list as they're part
    # of the default function set, not the workspace.
    #
    # They are defined in the fixtures/real_agent/cache/lib/...
    expect(deserial).to_not contain_child_with_key(:default_cache_function)
    expect(deserial).to_not contain_child_with_key(:default_pup4_function)
    expect(deserial).to_not contain_child_with_key(:'environment::default_env_pup4_function')
    expect(deserial).to_not contain_child_with_key(:'modname::default_mod_pup4_function')
    expect(deserial).to_not contain_child_with_key(:'defaultmodule::puppetfunc')
  end

  before(:each) do
    # Purge the File Cache
    cache = PuppetLanguageServerSidecar::Cache::FileSystem.new
    cache.clear!
  end

  after(:all) do
    # Purge the File Cache
    cache = PuppetLanguageServerSidecar::Cache::FileSystem.new
    cache.clear!
  end

  def expect_empty_cache
    cache = PuppetLanguageServerSidecar::Cache::FileSystem.new
    expect(Dir.exists?(cache.cache_dir)).to eq(true), "Expected the cache directory #{cache.cache_dir} to exist"
    expect(Dir.glob(File.join(cache.cache_dir,'*')).count).to eq(0), "Expected the cache directory #{cache.cache_dir} to be empty"
  end

  def expect_populated_cache
    cache = PuppetLanguageServerSidecar::Cache::FileSystem.new
    expect(Dir.glob(File.join(cache.cache_dir,'*')).count).to be > 0, "Expected the cache directory #{cache.cache_dir} to be populated"
  end

  def expect_same_array_content(a, b)
    expect(a.count).to eq(b.count), "Expected array with #{b.count} items to have #{a.count} items"

    a.each_with_index do |item, index|
      expect(item.to_json).to eq(b[index].to_json), "Expected item at index #{index} to have content #{item.to_json} but got #{b[index].to_json}"
    end
  end

  describe 'when running default_classes action' do
    let (:cmd_options) { ['--action', 'default_classes'] }

    it 'should return a cachable deserializable class list with default classes' do
      expect_empty_cache

      result = run_sidecar(cmd_options)
      deserial = PuppetLanguageServer::Sidecar::Protocol::PuppetClassList.new()
      expect { deserial.from_json!(result) }.to_not raise_error

      expect(deserial.count).to be > 0

      # There are no default classes in Puppet, so only check for ones in the environment
      # These are defined in the fixtures/real_agent/environments/testfixtures/modules/defaultmodule
      expect(deserial).to contain_child_with_key(:defaultdefinedtype)
      expect(deserial).to contain_child_with_key(:defaultmodule)

      # Make sure the classes have the right properties
      obj = child_with_key(deserial, :defaultdefinedtype)
      expect(obj.doc).to match(/This is an example of how to document a defined type/)
      expect(obj.source).to match(/defaultmodule/)
      expect(obj.parameters.count).to eq 2
      expect(obj.parameters['ensure'][:type]).to eq 'Any'
      expect(obj.parameters['ensure'][:doc]).to match(/Ensure parameter documentation/)
      expect(obj.parameters['param2'][:type]).to eq 'String'
      expect(obj.parameters['param2'][:doc]).to match(/param2 documentation/)

      obj = child_with_key(deserial, :defaultmodule)
      expect(obj.doc).to match(/This is an example of how to document a Puppet class/)
      expect(obj.source).to match(/defaultmodule/)
      expect(obj.parameters.count).to eq 2
      expect(obj.parameters['first'][:type]).to eq 'String'
      expect(obj.parameters['first'][:doc]).to match(/The first parameter for this class/)
      expect(obj.parameters['second'][:type]).to eq 'Integer'
      expect(obj.parameters['second'][:doc]).to match(/The second parameter for this class/)

      # Now run using cached information
      expect_populated_cache

      result2 = run_sidecar(cmd_options)
      deserial2 = PuppetLanguageServer::Sidecar::Protocol::PuppetClassList.new()
      expect { deserial2.from_json!(result2) }.to_not raise_error

      # The second result should be the same as the first
      expect_same_array_content(deserial, deserial2)
    end
  end

  describe 'when running default_functions action' do
    let (:cmd_options) { ['--action', 'default_functions'] }

    it 'should return a cachable deserializable function list with default functions' do
      expect_empty_cache

      result = run_sidecar(cmd_options)
      deserial = PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionList.new()
      expect { deserial.from_json!(result) }.to_not raise_error

      expect(deserial.count).to be > 0

      # These functions always exist
      expect(deserial).to contain_child_with_key(:notice)
      expect(deserial).to contain_child_with_key(:alert)

      # These are defined in the fixtures/real_agent/cache/lib/puppet/parser/functions
      expect(deserial).to contain_child_with_key(:default_cache_function)
      # These are defined in the fixtures/real_agent/cache/lib/puppet/functions
      expect(deserial).to contain_child_with_key(:default_pup4_function)
      # These are defined in the fixtures/real_agent/cache/lib/puppet/functions/environment (Special environent namespace)
      expect(deserial).to contain_child_with_key(:'environment::default_env_pup4_function')
      # These are defined in the fixtures/real_agent/cache/lib/puppet/functions/modname (module namespaced function)
      expect(deserial).to contain_child_with_key(:'modname::default_mod_pup4_function')
      # These are defined in the fixtures/real_agent/environments/testfixtures/modules/defaultmodules/functions/puppetfunc.pp
      expect(deserial).to contain_child_with_key(:'defaultmodule::puppetfunc')

      # Now run using cached information
      expect_populated_cache

      result2 = run_sidecar(cmd_options)
      deserial2 = PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionList.new()
      expect { deserial2.from_json!(result2) }.to_not raise_error

      # The second result should be the same as the first
      expect_same_array_content(deserial, deserial2)
    end
  end

  describe 'when running default_types action' do
    let (:cmd_options) { ['--action', 'default_types'] }

    it 'should return a cachable deserializable type list with default types' do
      expect_empty_cache

      result = run_sidecar(cmd_options)
      deserial = PuppetLanguageServer::Sidecar::Protocol::PuppetTypeList.new()
      expect { deserial.from_json!(result) }.to_not raise_error

      expect(deserial.count).to be > 0

      # These types always exist
      expect(deserial).to contain_child_with_key(:user)
      expect(deserial).to contain_child_with_key(:group)
      expect(deserial).to contain_child_with_key(:package)
      expect(deserial).to contain_child_with_key(:service)

      # These are defined in the fixtures/real_agent/cache/lib/puppet/type
      expect(deserial).to contain_child_with_key(:default_type)

      # Now run using cached information
      expect_populated_cache

      result2 = run_sidecar(cmd_options)
      deserial2 = PuppetLanguageServer::Sidecar::Protocol::PuppetTypeList.new()
      expect { deserial2.from_json!(result2) }.to_not raise_error

      # The second result should be the same as the first
      expect_same_array_content(deserial, deserial2)
    end
  end

  context 'given a workspace containing a module' do
    # Test fixtures used is fixtures/valid_module_workspace
    let(:workspace) { File.join($fixtures_dir, 'valid_module_workspace') }

    describe 'when running node_graph action' do
      let (:cmd_options) { ['--action', 'node_graph', '--local-workspace', workspace] }

      it 'should return a deserializable node graph' do
        # The fixture type is only present in the local workspace
        with_temporary_file("fixture { 'test':\n}") do |filepath|
          action_params = PuppetLanguageServer::Sidecar::Protocol::ActionParams.new()
          action_params['source'] = filepath

          result = run_sidecar(cmd_options.concat(['--action-parameters', action_params.to_json]))

          deserial = PuppetLanguageServer::Sidecar::Protocol::NodeGraph.new()
          expect { deserial.from_json!(result) }.to_not raise_error

          expect(deserial.dot_content).to match(/Fixture\[test\]/)
          expect(deserial.error_content.to_s).to eq('')
        end
      end
    end

    describe 'when running workspace_classes action' do
      let (:cmd_options) { ['--action', 'workspace_classes', '--local-workspace', workspace] }

      it 'should return a deserializable class list with the named fixtures' do
        result = run_sidecar(cmd_options)
        deserial = PuppetLanguageServer::Sidecar::Protocol::PuppetClassList.new()
        expect { deserial.from_json!(result) }.to_not raise_error

        # Classes
        expect(deserial).to contain_child_with_key(:valid)
        expect(deserial).to contain_child_with_key(:"valid::nested::anotherclass")
        # Defined Types
        expect(deserial).to contain_child_with_key(:deftypeone)
      end
    end

    describe 'when running workspace_functions action' do
      let (:cmd_options) { ['--action', 'workspace_functions', '--local-workspace', workspace] }

      it 'should return a deserializable function list with the named fixtures' do
        result = run_sidecar(cmd_options)
        deserial = PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionList.new()
        expect { deserial.from_json!(result) }.to_not raise_error

        should_not_contain_default_functions(deserial)

        # Puppet 3 API Functions
        expect(deserial).to_not contain_child_with_key(:badfile)
        expect(deserial).to contain_child_with_key(:bad_function)
        expect(deserial).to contain_child_with_key(:fixture_function)

        # Puppet 4 API Functions
        # The strings based parser will still see 'fixture_pup4_badfile' because it's never _actually_ loaded
        # in Puppet therefore it will never error
        expect(deserial).to contain_child_with_key(:fixture_pup4_badfile)
        # The strings based parser will still see 'badname::fixture_pup4_badname_function' because it's never _actually_ loaded
        # in Puppet therefore it will never error
        expect(deserial).to contain_child_with_key(:'badname::fixture_pup4_badname_function')
        expect(deserial).to contain_child_with_key(:fixture_pup4_function)
        expect(deserial).to contain_child_with_key(:'valid::fixture_pup4_mod_function')
        expect(deserial).to contain_child_with_key(:fixture_pup4_badfunction)
        expect(deserial).to contain_child_with_key(:'valid::modulefunc')

        # Make sure the function has the right properties
        func = child_with_key(deserial, :fixture_function)
        expect(func.doc).to match(/doc_fixture_function/)
        expect(func.source).to match(/valid_module_workspace/)

        # Make sure the function has the right properties
        func = child_with_key(deserial, :fixture_pup4_function)
        expect(func.doc).to match(/Example function using the Puppet 4 API in a module/)
        expect(func.source).to match(/valid_module_workspace/)

        # Make sure the function has the right properties
        func = child_with_key(deserial, :'valid::modulefunc')
        expect(func.function_version).to eq(4) # Puppet Langauge functions are V4
        expect(func.doc).to match(/An example puppet function in a module, as opposed to a ruby custom function/)
        expect(func.source).to match(/valid_module_workspace/)
        expect(func.signatures.count).to be > 0
      end
    end

    describe 'when running workspace_types action' do
      let (:cmd_options) { ['--action', 'workspace_types', '--local-workspace', workspace] }

      it 'should return a deserializable type list with the named fixtures' do
        result = run_sidecar(cmd_options)
        deserial = PuppetLanguageServer::Sidecar::Protocol::PuppetTypeList.new()
        expect { deserial.from_json!(result) }.to_not raise_error

        expect(deserial).to contain_child_with_key(:fixture)

        # Make sure the type has the right properties
        obj = child_with_key(deserial, :fixture)
        expect(obj.doc).to eq('doc_type_fixture')
        expect(obj.source).to match(/valid_module_workspace/)
        # Make sure the type attributes are correct
        expect(obj.attributes.key?(:name)).to be true
        expect(obj.attributes.key?(:when)).to be true
        expect(obj.attributes[:name][:type]).to eq(:param)
        expect(obj.attributes[:name][:doc]).to eq("name_parameter")
        expect(obj.attributes[:name][:isnamevar?]).to be true
        expect(obj.attributes[:when][:type]).to eq(:property)
        expect(obj.attributes[:when][:doc]).to eq("when_property")
      end
    end
  end

  context 'given a workspace containing an environment.conf' do
    # Test fixtures used is fixtures/valid_environment_workspace
    let(:workspace) { File.join($fixtures_dir, 'valid_environment_workspace') }

    describe 'when running node_graph action' do
      let (:cmd_options) { ['--action', 'node_graph', '--local-workspace', workspace] }

      it 'should return a deserializable node graph' do
        # The envtype type is only present in the local workspace
        with_temporary_file("envtype { 'test':\n}") do |filepath|
          action_params = PuppetLanguageServer::Sidecar::Protocol::ActionParams.new()
          action_params['source'] = filepath

          result = run_sidecar(cmd_options.concat(['--action-parameters', action_params.to_json]))

          deserial = PuppetLanguageServer::Sidecar::Protocol::NodeGraph.new()
          expect { deserial.from_json!(result) }.to_not raise_error

          expect(deserial.dot_content).to match(/Envtype\[test\]/)
          expect(deserial.error_content.to_s).to eq('')
        end
      end
    end

    describe 'when running workspace_classes action' do
      let (:cmd_options) { ['--action', 'workspace_classes', '--local-workspace', workspace] }

      it 'should return a deserializable class list with the named fixtures' do
        result = run_sidecar(cmd_options)
        deserial = PuppetLanguageServer::Sidecar::Protocol::PuppetClassList.new()
        expect { deserial.from_json!(result) }.to_not raise_error

        # Classes
        expect(deserial).to contain_child_with_key(:"role::base")
        expect(deserial).to contain_child_with_key(:"profile::main")
        # Defined Types
        expect(deserial).to contain_child_with_key(:envdeftype)

        # Make sure the class has the right properties
        obj = child_with_key(deserial, :envdeftype)
        expect(obj.doc).to_not be_nil
        expect(obj.parameters['ensure']).to_not be_nil
        expect(obj.parameters['ensure'][:type]).to eq('String')
        expect(obj.source).to match(/valid_environment_workspace/)
      end
    end

    describe 'when running workspace_functions action' do
      let (:cmd_options) { ['--action', 'workspace_functions', '--local-workspace', workspace] }

      it 'should return a deserializable function list with the named fixtures' do
        result = run_sidecar(cmd_options)
        deserial = PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionList.new()
        expect { deserial.from_json!(result) }.to_not raise_error

        should_not_contain_default_functions(deserial)

        # The strings based parser will still see 'pup4_env_badfile' because it's never _actually_ loaded
        # in Puppet therefore it will never error
        expect(deserial).to contain_child_with_key(:pup4_env_badfile)
        # The strings based parser will still see 'badname::pup4_function' because it's never _actually_ loaded
        # in Puppet therefore it will never error
        expect(deserial).to contain_child_with_key(:'badname::pup4_function')
        expect(deserial).to contain_child_with_key(:env_function)
        expect(deserial).to contain_child_with_key(:pup4_env_function)
        expect(deserial).to contain_child_with_key(:pup4_env_badfunction)
        expect(deserial).to contain_child_with_key(:'profile::pup4_envprofile_function')

        # Make sure the function has the right properties
        func = child_with_key(deserial, :env_function)
        expect(func.doc).to match(/doc_env_function/)
        expect(func.source).to match(/valid_environment_workspace/)

        # Make sure the function has the right properties
        func = child_with_key(deserial, :pup4_env_function)
        expect(func.doc).to match(/Example function using the Puppet 4 API in a module/)
        expect(func.source).to match(/valid_environment_workspace/)
      end
    end

    describe 'when running workspace_types action' do
      let (:cmd_options) { ['--action', 'workspace_types', '--local-workspace', workspace] }

      it 'should return a deserializable type list with the named fixtures' do
        result = run_sidecar(cmd_options)
        deserial = PuppetLanguageServer::Sidecar::Protocol::PuppetTypeList.new()
        expect { deserial.from_json!(result) }.to_not raise_error

        expect(deserial).to contain_child_with_key(:envtype)

        # Make sure the type has the right properties
        obj = child_with_key(deserial, :envtype)
        expect(obj.doc).to eq('doc_type_fixture')
        expect(obj.source).to match(/valid_environment_workspace/)
        # Make sure the type attributes are correct
        expect(obj.attributes.key?(:name)).to be true
        expect(obj.attributes.key?(:when)).to be true
        expect(obj.attributes[:name][:type]).to eq(:param)
        expect(obj.attributes[:name][:doc]).to eq("name_env_parameter")
        expect(obj.attributes[:name][:isnamevar?]).to be true
        expect(obj.attributes[:when][:type]).to eq(:property)
        expect(obj.attributes[:when][:doc]).to eq("when_env_property")
      end
    end
  end

  describe 'when running node_graph action' do
    let (:cmd_options) { ['--action', 'node_graph'] }

    it 'should return a deserializable node graph' do
      with_temporary_file("user { 'test':\nensure => present\n}") do |filepath|
        action_params = PuppetLanguageServer::Sidecar::Protocol::ActionParams.new()
        action_params['source'] = filepath

        result = run_sidecar(cmd_options.concat(['--action-parameters', action_params.to_json]))

        deserial = PuppetLanguageServer::Sidecar::Protocol::NodeGraph.new()
        expect { deserial.from_json!(result) }.to_not raise_error

        expect(deserial.dot_content).to_not eq('')
        expect(deserial.error_content.to_s).to eq('')
      end
    end
  end

  describe 'when running resource_list action' do
    let (:cmd_options) { ['--action', 'resource_list'] }

    context 'for a resource with no title' do
      let (:action_params) {
        value = PuppetLanguageServer::Sidecar::Protocol::ActionParams.new()
        value['typename'] = 'user'
        value
      }

      it 'should return a deserializable resource list' do
        result = run_sidecar(cmd_options.concat(['--action-parameters', action_params.to_json]))
        deserial = PuppetLanguageServer::Sidecar::Protocol::ResourceList.new()
        expect { deserial.from_json!(result) }.to_not raise_error

        expect(deserial.count).to be > 0
      end
    end

    context 'for a resource with a title' do
      let (:action_params) {
        # This may do odd things with non ASCII usernames on Windows
        current_username = ENV['USER'] || ENV['USERNAME']

        value = PuppetLanguageServer::Sidecar::Protocol::ActionParams.new()
        value['typename'] = 'user'
        value['title'] = current_username
        value
      }

      it 'should return a deserializable resource list with a single item' do
        result = run_sidecar(cmd_options.concat(['--action-parameters', action_params.to_json]))
        deserial = PuppetLanguageServer::Sidecar::Protocol::ResourceList.new()
        expect { deserial.from_json!(result) }.to_not raise_error

        expect(deserial.count).to be 1
      end
    end
  end
end
