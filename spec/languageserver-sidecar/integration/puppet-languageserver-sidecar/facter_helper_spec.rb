require 'spec_helper'
require 'open3'

describe 'PuppetLanguageServerSidecar::FacterHelper', :if => Gem::Version.new(Puppet.version) >= Gem::Version.new('5.0.0') do
  let(:subject) { PuppetLanguageServerSidecar::FacterHelper }

  def run_sidecar(cmd_options)
    # Use a new array so we don't affect the original cmd_options)
    cmd = cmd_options.dup

    # Append the puppet test-fixtures
    cmd << '--puppet-settings'
    cmd << "--vardir,#{File.join($fixtures_dir, 'real_agent', 'cache')},--confdir,#{File.join($fixtures_dir, 'real_agent', 'confdir')}"

    cmd.unshift('puppet-languageserver-sidecar')
    cmd.unshift('ruby')
    stdout, _stderr, status = Open3.capture3(*cmd)

    raise "Expected exit code of 0, but got #{status.exitstatus} #{_stderr}" unless status.exitstatus.zero?
    return stdout.bytes.pack('U*')
  end

  RSpec::Matchers.define :contain_child_with_key do |key|
    match do |actual|
      !(actual.index { |item| item.key == key }).nil?
    end

    failure_message do |actual|
      "expected that #{actual.class.to_s} would contain a child with key #{key}"
    end
  end

  let(:default_fact_names) { %i[hostname fixture_agent_custom_fact] }
  let(:module_fact_names) { %i[fixture_module_custom_fact fixture_module_external_fact] }
  let(:environment_fact_names) { %i[fixture_environment_custom_fact fixture_environment_external_fact] }

  describe 'when running facts action' do
    let (:cmd_options) { ['--action', 'facts'] }

    it 'should return a deserializable facts object with all default facts' do
      result = run_sidecar(cmd_options)
      deserial = PuppetLanguageServer::Sidecar::Protocol::FactList.new
      expect { deserial.from_json!(result) }.to_not raise_error
      default_fact_names.each do |name|
        expect(deserial).to contain_child_with_key(name)
      end

      module_fact_names.each do |name|
        expect(deserial).to_not contain_child_with_key(name)
      end
    end
  end

  context 'given a workspace containing a module' do
    # Test fixtures used is fixtures/valid_module_workspace
    let(:workspace) { File.join($fixtures_dir, 'valid_module_workspace') }

    describe 'when running facts action' do
      let (:cmd_options) { ['--action', 'facts', '--local-workspace', workspace] }

      it 'should return a deserializable facts object with default facts and workspace facts' do
        result = run_sidecar(cmd_options)
        deserial = PuppetLanguageServer::Sidecar::Protocol::FactList.new
        expect { deserial.from_json!(result) }.to_not raise_error

        default_fact_names.each do |name|
          expect(deserial).to contain_child_with_key(name)
        end

        module_fact_names.each do |name|
          expect(deserial).to contain_child_with_key(name)
        end
      end
    end
  end

  context 'given a workspace containing an environment.conf' do
    # Test fixtures used is fixtures/valid_environment_workspace
    let(:workspace) { File.join($fixtures_dir, 'valid_environment_workspace') }

    describe 'when running facts action' do
      let (:cmd_options) { ['--action', 'facts', '--local-workspace', workspace] }

      it 'should return a deserializable facts object with default facts and workspace facts' do
        result = run_sidecar(cmd_options)
        deserial = PuppetLanguageServer::Sidecar::Protocol::FactList.new
        expect { deserial.from_json!(result) }.to_not raise_error

        default_fact_names.each do |name|
          expect(deserial).to contain_child_with_key(name)
        end

        environment_fact_names.each do |name|
          expect(deserial).to contain_child_with_key(name)
        end
      end
    end
  end
end
