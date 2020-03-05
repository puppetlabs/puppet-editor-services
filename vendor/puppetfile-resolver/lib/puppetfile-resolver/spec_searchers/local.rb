# frozen_string_literal: true

require 'puppetfile-resolver/spec_searchers/common'

module PuppetfileResolver
  module SpecSearchers
    module Local
      def self.find_all(_puppetfile_module, puppet_module_paths, dependency, cache, resolver_ui)
        dep_id = ::PuppetfileResolver::SpecSearchers::Common.dependency_cache_id(self, dependency)
        # Has the information been cached?
        return cache.load(dep_id) if cache.exist?(dep_id)

        result = []
        # Find the module in the modulepaths
        puppet_module_paths.each do |module_path|
          next unless Dir.exist?(module_path)
          module_dir = File.expand_path(File.join(module_path, dependency.name))
          next unless Dir.exist?(module_dir)
          metadata_file = File.join(module_dir, 'metadata.json')
          next unless File.exist?(metadata_file)

          metadata = nil
          begin
            metadata = ::PuppetfileResolver::Util.symbolise_object(
              ::JSON.parse(File.open(metadata_file, 'rb:utf-8') { |f| f.read })
            )
          rescue StandardError => _e # rubocop:disable Lint/SuppressedException Todo
            # TODO: Should really do something?
          end
          resolver_ui.debug { "Found local module at #{metadata_file}" }

          result << Models::ModuleSpecification.new(
            name: metadata[:name],
            origin: :local,
            version: metadata[:version],
            metadata: metadata
          )
        end
        cache.save(dep_id, result)

        result
      end
    end
  end
end
