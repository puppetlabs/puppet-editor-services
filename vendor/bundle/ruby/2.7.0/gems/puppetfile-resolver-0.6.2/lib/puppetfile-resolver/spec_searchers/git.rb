# frozen_string_literal: true

require 'puppetfile-resolver/util'
require 'puppetfile-resolver/spec_searchers/common'
require 'puppetfile-resolver/spec_searchers/git_configuration'
require 'puppetfile-resolver/spec_searchers/git/github'
require 'puppetfile-resolver/spec_searchers/git/gitlab'
require 'puppetfile-resolver/spec_searchers/git/gclone'

module PuppetfileResolver
  module SpecSearchers
    module Git
      def self.find_all(puppetfile_module, dependency, cache, resolver_ui, config)
        dep_id = ::PuppetfileResolver::SpecSearchers::Common.dependency_cache_id(self, dependency)
        # Has the information been cached?
        return cache.load(dep_id) if cache.exist?(dep_id)

        # The git clone method takes around (1s) depending on repo size.  Not sure if the
        # other methods take longer or shorter but I preserved the legacy code for now.
        # Technically, the gclone class could replace the other classes and speed up
        # this process here.
        metadata = GitHub.metadata(puppetfile_module, resolver_ui, config) ||
                   GitLab.metadata(puppetfile_module, resolver_ui, config) ||
                   GClone.metadata(puppetfile_module, resolver_ui, config)

        if metadata.nil? || metadata.empty?
          # Cache that we couldn't find the metadata
          cache.save(dep_id, [])
          return []
        end

        metadata = ::PuppetfileResolver::Util.symbolise_object(::JSON.parse(metadata))
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
