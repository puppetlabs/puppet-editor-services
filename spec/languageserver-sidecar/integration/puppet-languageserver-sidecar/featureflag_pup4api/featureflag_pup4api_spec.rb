require 'spec_helper'
require 'open3'
require 'tempfile'

describe 'PuppetLanguageServerSidecar with Feature Flag pup4api', :if => PuppetLanguageServerSidecar.puppet_pal_supported? do
  def run_sidecar(cmd_options)
    cmd_options << '--no-cache'

    # Append the feature flag
    cmd_options << '--feature-flag=pup4api'

    # Append the puppet test-fixtures
    cmd_options << '--puppet-settings'
    cmd_options << "--vardir,#{File.join($fixtures_dir, 'real_agent', 'cache')},--confdir,#{File.join($fixtures_dir, 'real_agent', 'confdir')}"

    cmd = ['ruby', 'puppet-languageserver-sidecar'].concat(cmd_options)
# DEBUG
puts cmd.join(' ')
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

  describe 'when running default_functions action' do
    let (:cmd_options) { ['--action', 'default_functions'] }

    it 'should return a deserializable function list with default functions' do
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
      expect(deserial).to contain_child_with_key(:default_env_pup4_function)
      # These are defined in the fixtures/real_agent/cache/lib/puppet/functions/modname (module namespaced function)
      expect(deserial).to contain_child_with_key(:'modname::default_mod_pup4_function')
    end
  end

  context 'given a workspace containing a module' do
    # Test fixtures used is fixtures/valid_module_workspace
    let(:workspace) { File.join($fixtures_dir, 'valid_module_workspace') }

    describe 'when running workspace_functions action' do
      let (:cmd_options) { ['--action', 'workspace_functions', '--local-workspace', workspace] }

      it 'should return a deserializable function list with the named fixtures' do
        result = run_sidecar(cmd_options)
        deserial = PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionList.new()
        expect { deserial.from_json!(result) }.to_not raise_error

        # Puppet 3 API Functions
        expect(deserial).to_not contain_child_with_key(:badfile)
        expect(deserial).to contain_child_with_key(:bad_function)
        expect(deserial).to contain_child_with_key(:fixture_function)

        # Puppet 4 API Functions
        expect(deserial).to_not contain_child_with_key(:fixture_pup4_badfile)
        expect(deserial).to_not contain_child_with_key(:'badname::fixture_pup4_badname_function')
        expect(deserial).to contain_child_with_key(:fixture_pup4_function)
        expect(deserial).to contain_child_with_key(:'valid::fixture_pup4_mod_function')
        expect(deserial).to contain_child_with_key(:fixture_pup4_badfunction)

        # Make sure the function has the right properties
        func = child_with_key(deserial, :fixture_function)
        expect(func.doc).to eq('doc_fixture_function')
        expect(func.source).to match(/valid_module_workspace/)
        expect(func.version).to eq(3)

        # Make sure the function has the right properties
        func = child_with_key(deserial, :fixture_pup4_function)
        expect(func.doc).to be_nil  # Currently we can't get the documentation for v4 functions
        expect(func.source).to match(/valid_module_workspace/)
        expect(func.version).to eq(4)
        expect(func.signatures).to_not be_nil
      end
    end
  end

  context 'given a workspace containing an environment.conf' do
    # Test fixtures used is fixtures/valid_environment_workspace
    let(:workspace) { File.join($fixtures_dir, 'valid_environment_workspace') }

    describe 'when running workspace_functions action' do
      let (:cmd_options) { ['--action', 'workspace_functions', '--local-workspace', workspace] }

      it 'should return a deserializable function list with the named fixtures' do
        result = run_sidecar(cmd_options)
        deserial = PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionList.new()
        expect { deserial.from_json!(result) }.to_not raise_error

        expect(deserial).to_not contain_child_with_key(:pup4_env_badfile)
        expect(deserial).to_not contain_child_with_key(:'badname::pup4_function')
        expect(deserial).to contain_child_with_key(:env_function)
        expect(deserial).to contain_child_with_key(:pup4_env_function)
        expect(deserial).to contain_child_with_key(:pup4_env_badfunction)
        expect(deserial).to contain_child_with_key(:'profile::pup4_envprofile_function')

        # Make sure the function has the right properties
        func = child_with_key(deserial, :env_function)
        expect(func.doc).to eq('doc_env_function')
        expect(func.source).to match(/valid_environment_workspace/)
        expect(func.version).to eq(3)

        # Make sure the function has the right properties
        func = child_with_key(deserial, :pup4_env_function)
        expect(func.doc).to be_nil  # Currently we can't get the documentation for v4 functions
        expect(func.source).to match(/valid_environment_workspace/)
        expect(func.version).to eq(4)
        expect(func.signatures).to_not be_nil
      end
    end
  end
end
