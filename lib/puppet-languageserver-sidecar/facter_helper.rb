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
      facts = PuppetLanguageServer::Sidecar::Protocol::Facts.new
      begin
        req = Puppet::Indirector::Request.new(:facts, :find, 'language_server', nil, environment: current_environment)
        result = Puppet::Node::Facts::Facter.new.find(req)
        facts.from_h!(result.values)
      rescue StandardError => e
        PuppetLanguageServerSidecar.log_message(:error, "[FacterHelper::_load_facts] Error loading facts #{e.message} #{e.backtrace}")
      rescue LoadError => e
        PuppetLanguageServerSidecar.log_message(:error, "[FacterHelper::_load_facts] Error loading facts (LoadError) #{e.message} #{e.backtrace}")
      end

      PuppetLanguageServerSidecar.log_message(:debug, "[FacterHelper::retrieve_facts] Finished loading #{facts.keys.count} facts")
      facts
    end
  end
end
