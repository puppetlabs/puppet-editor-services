# frozen_string_literal: true

require 'puppetfile-resolver/spec_searchers/common'

module PuppetfileResolver
  module SpecSearchers
    module Git
      def self.find_all(puppetfile_module, dependency, cache, resolver_ui)
        dep_id = ::PuppetfileResolver::SpecSearchers::Common.dependency_cache_id(self, dependency)
        # Has the information been cached?
        return cache.load(dep_id) if cache.exist?(dep_id)

        # We _could_ git clone this, but it'll take too long. So for now, just
        # try and resolve github based repositories by crafting a URL

        repo_url = nil
        if puppetfile_module.remote.start_with?('git@github.com:')
          repo_url = puppetfile_module.remote.slice(15..-1)
          repo_url = repo_url.slice(0..-5) if repo_url.end_with?('.git')
        end
        if puppetfile_module.remote.start_with?('https://github.com/')
          repo_url = puppetfile_module.remote.slice(19..-1)
          repo_url = repo_url.slice(0..-5) if repo_url.end_with?('.git')
        end

        return [] if repo_url.nil?

        metadata_url = 'https://raw.githubusercontent.com/' + repo_url + '/'
        if puppetfile_module.ref
          metadata_url += puppetfile_module.ref + '/'
        elsif puppetfile_module.tag
          metadata_url += puppetfile_module.tag + '/'
        else
          # Default to master.  Should it raise?
          metadata_url += 'master/'
        end
        metadata_url += 'metadata.json'

        require 'net/http'
        require 'uri'

        resolver_ui.debug { "Querying the Github with #{metadata_url}" }
        response = Net::HTTP.get_response(URI.parse(metadata_url))
        if response.code != '200'
          cache.save(dep_id, [])
          return []
        end

        # TODO: symbolise_object should be in a Util namespace
        metadata = ::PuppetfileResolver::Util.symbolise_object(::JSON.parse(response.body))
        result = [Models::ModuleSpecification.new(
          name: metadata[:name],
          origin: :git,
          version: metadata[:version],
          metadata: metadata
        )]

        cache.save(dep_id, result)

        result
      end
    end
  end
end
