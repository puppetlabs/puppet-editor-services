# frozen_string_literal: true

require 'puppetfile-resolver/spec_searchers/common'
require 'uri'
require 'net/http'
require 'openssl'
require 'json'

module PuppetfileResolver
  module SpecSearchers
    module Forge
      DEFAULT_FORGE_URI ||= 'https://forgeapi.puppet.com'

      def self.find_all(dependency, cache, resolver_ui)
        dep_id = ::PuppetfileResolver::SpecSearchers::Common.dependency_cache_id(self, dependency)

        # Has the information been cached?
        return cache.load(dep_id) if cache.exist?(dep_id)

        result = []
        # Query the forge
        fetch_all_module_releases(dependency.owner, dependency.name, resolver_ui) do |partial_releases|
          partial_releases.each do |release|
            result << Models::ModuleSpecification.new(
              name: release['module']['name'],
              owner: release['module']['owner']['slug'],
              origin: :forge,
              version: release['version'],
              metadata: ::PuppetfileResolver::Util.symbolise_object(release['metadata'])
            )
          end
        end

        cache.save(dep_id, result)
        result
      end

      def self.fetch_all_module_releases(owner, name, forge_api_url = DEFAULT_FORGE_URI, resolver_ui, &block)
        raise 'Requires a block to yield' unless block
        uri = ::URI.parse("#{forge_api_url}/v3/releases")
        params = { :module => "#{owner}-#{name}", :exclude_fields => 'readme changelog license reference tasks', :limit => 50 }
        uri.query = ::URI.encode_www_form(params)

        loops = 0
        loop do
          resolver_ui.debug { "Querying the forge for a module with #{uri}" }

          http_options = { :use_ssl => uri.class == URI::HTTPS }
          # Because on Windows Ruby doesn't use the Windows certificate store which has up-to date
          # CA certs, we can't depend on someone setting the environment variable correctly. So use our
          # static CA PEM file if SSL_CERT_FILE is not set.
          http_options[:ca_file] = PuppetfileResolver::Util.static_ca_cert_file if ENV['SSL_CERT_FILE'].nil?

          response = nil
          Net::HTTP.start(uri.host, uri.port, http_options) do |http|
            request = Net::HTTP::Get.new uri
            response = http.request request
          end
          raise "Expected HTTP Code 200, but received #{response.code} for URI #{uri}: #{response.inspect}" unless response.code == '200'

          reply = ::JSON.parse(response.body)
          yield reply['results']

          break if reply['pagination'].nil? || reply['pagination']['next'].nil?
          uri = ::URI.parse("#{forge_api_url}#{reply['pagination']['next']}")

          # Circuit breaker in case the worst happens (max 1000 module releases)
          loops += 1
          raise "Too many Forge API requests #{loops * 50}" if loops > 20
        end
      end
      private_class_method :fetch_all_module_releases
    end
  end
end
