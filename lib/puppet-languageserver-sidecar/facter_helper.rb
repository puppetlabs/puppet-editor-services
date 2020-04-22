# frozen_string_literal: true

module PuppetLanguageServerSidecar
  module FacterHelper
    def self.current_environment
      begin
        env = Puppet.lookup(:environments).get!(Puppet.settings[:environment])
        return env unless env.nil?
      rescue Puppet::Environments::EnvironmentNotFound
        PuppetLanguageServerSidecar.log_message(:warning, "[FacterHelper::current_environment] Unable to load environment #{Puppet.settings[:environment]}")
      rescue StandardError => e
        PuppetLanguageServerSidecar.log_message(:warning, "[FacterHelper::current_environment] Error loading environment #{Puppet.settings[:environment]}: #{e}")
      end
      Puppet.lookup(:current_environment)
    end

    def self.retrieve_facts(_cache, _options = {})
      require 'puppet/indirector/facts/facter'

      PuppetLanguageServerSidecar.log_message(:debug, '[FacterHelper::retrieve_facts] Starting')
      facts = PuppetLanguageServer::Sidecar::Protocol::FactList.new
      begin
        req = Puppet::Indirector::Request.new(:facts, :find, 'language_server', nil, environment: current_environment)
        result = Puppet::Node::Facts::Facter.new.find(req)
        result.values.each do |key, value|
          # TODO: This isn't strictly correct e.g. fully qualified facts will look a bit odd.
          # Consider a fact called foo.bar.baz = 'Hello'.  Even though the fact name is `foo.bar.baz`
          # it will appear in the facts object as `facts['foo'] = { 'bar' => { 'baz' => 'Hello' }}`
          facts << PuppetLanguageServer::Sidecar::Protocol::Fact.new.from_h!('key' => key, 'value' => value)
        end
      rescue StandardError => e
        PuppetLanguageServerSidecar.log_message(:error, "[FacterHelper::_load_facts] Error loading facts #{e.message} #{e.backtrace}")
      rescue LoadError => e
        PuppetLanguageServerSidecar.log_message(:error, "[FacterHelper::_load_facts] Error loading facts (LoadError) #{e.message} #{e.backtrace}")
      end

      PuppetLanguageServerSidecar.log_message(:debug, "[FacterHelper::retrieve_facts] Finished loading #{facts.count} facts")
      facts
    end
  end
end
