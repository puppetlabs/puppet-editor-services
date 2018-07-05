require 'spec_helper'
require 'open3'

def run_sidecar(cmd_options)
  cmd_options << '--no-cache'

  # Append the puppet test-fixtures
  cmd_options << '--puppet-settings'
  cmd_options << "--vardir,#{File.join($fixtures_dir, 'real_agent', 'cache')},--confdir,#{File.join($fixtures_dir, 'real_agent', 'confdir')}"

  cmd = ['ruby', 'puppet-languageserver-sidecar'].concat(cmd_options)
  stdout, _stderr, status = Open3.capture3(*cmd)

  raise "Expected exit code of 0, but got #{status.exitstatus}" unless status.exitstatus.zero?
  return stdout.bytes.pack('U*')
end

def child_with_key(array, key)
  idx = array.index { |item| item.key == key }
  return idx.nil? ? nil : array[idx]
end

RSpec::Matchers.define :contain_child_with_key do |key|
  match do |actual|
    !(actual.index { |item| item.key == key }).nil?
  end

  failure_message do |actual|
    "expected that #{actual.class.to_s} would contain a child with key #{key}"
  end
end

describe 'PuppetLanguageServerSidecar' do
  describe 'when running default_classes action' do
    let (:cmd_options) { ['--action', 'default_classes'] }

    it 'should return a deserializable class list with default classes' do
      result = run_sidecar(cmd_options)
      deserial = PuppetLanguageServer::Sidecar::Protocol::PuppetClassList.new()
      expect { deserial.from_json!(result) }.to_not raise_error

      expect(deserial.count).to be > 0

      # There are no default classes in Puppet, so only check for ones in the environment
      # These are defined in the fixtures/real_agent/environments/testfixtures/modules/defaultmodule
      expect(deserial).to contain_child_with_key(:defaultdefinedtype)
      expect(deserial).to contain_child_with_key(:defaultmodule)
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
    end
  end

  describe 'when running default_types action' do
    let (:cmd_options) { ['--action', 'default_types'] }

    it 'should return a deserializable type list with default types' do
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
    end
  end

  context 'given a workspace containing a module' do
    # Test fixtures used is fixtures/valid_module_workspace
    let(:workspace) { File.join($fixtures_dir, 'valid_module_workspace') }

    describe 'when running workspace_classes action' do
      let (:cmd_options) { ['--action', 'workspace_classes', '--local-workspace',workspace] }

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
      let (:cmd_options) { ['--action', 'workspace_functions', '--local-workspace',workspace] }

      it 'should return a deserializable function list with the named fixtures' do
        result = run_sidecar(cmd_options)
        deserial = PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionList.new()
        expect { deserial.from_json!(result) }.to_not raise_error

        expect(deserial).to_not contain_child_with_key(:badfile)
        expect(deserial).to contain_child_with_key(:bad_function)
        expect(deserial).to contain_child_with_key(:fixture_function)

        # Make sure the function has the right properties
        func = child_with_key(deserial, :fixture_function)
        expect(func.doc).to eq('doc_fixture_function')
        expect(func.source).to match(/valid_module_workspace/)
      end
    end

    describe 'when running workspace_types action' do
      let (:cmd_options) { ['--action', 'workspace_types', '--local-workspace',workspace] }

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
        expect(obj.attributes[:name][:doc]).to eq("name_parameter\n\n")
        expect(obj.attributes[:name][:required?]).to be true
        expect(obj.attributes[:when][:type]).to eq(:property)
        expect(obj.attributes[:when][:doc]).to eq("when_property\n\n")
        expect(obj.attributes[:when][:required?]).to be_nil
      end
    end
  end
end
