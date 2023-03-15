# frozen_string_literal: true

require 'puppetfile-resolver/util'
require 'puppetfile-resolver/spec_searchers/common'
require 'puppetfile-resolver/spec_searchers/git_configuration'

module PuppetfileResolver
  module SpecSearchers
    module Git
      module GitLab
        def self.metadata(puppetfile_module, resolver_ui, config)
          repo_url = nil
          if puppetfile_module.remote.start_with?('git@gitlab.com:')
            repo_url = puppetfile_module.remote.slice(15..-1)
            repo_url = repo_url.slice(0..-5) if repo_url.end_with?('.git')
          elsif puppetfile_module.remote.start_with?('https://gitlab.com/')
            repo_url = puppetfile_module.remote.slice(19..-1)
            repo_url = repo_url.slice(0..-5) if repo_url.end_with?('.git')
          end
          return nil if repo_url.nil?

          # Example URL
          # https://gitlab.com/simp/pupmod-simp-crypto_policy/-/raw/0.1.4/metadata.json
          metadata_url = 'https://gitlab.com/' + repo_url + '/-/raw/'
          if puppetfile_module.ref
            metadata_url += puppetfile_module.ref + '/'
          elsif puppetfile_module.tag
            metadata_url += puppetfile_module.tag + '/'
          else
            # Default to master. Should it raise?
            metadata_url += 'master/'
          end
          metadata_url += 'metadata.json'

          resolver_ui.debug { "Querying GitLab with #{metadata_url}" }
          err_msg = "Unable to find module at #{puppetfile_module.remote}"
          err_msg += config.proxy ? " with proxy #{config.proxy}: " : ': '
          response = nil

          begin
            response = ::PuppetfileResolver::Util.net_http_get(metadata_url, config.proxy)
          rescue ::StandardError => e
            raise err_msg + e.message
          end

          if response.code != '200'
            resolver_ui.debug(err_msg + "Expected HTTP Code 200, but received #{response.code}")
            return nil
          end
          response.body
        end
      end
    end
  end
end
