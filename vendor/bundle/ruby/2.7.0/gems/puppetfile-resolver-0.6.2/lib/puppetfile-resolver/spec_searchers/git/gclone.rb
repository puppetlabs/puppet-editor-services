# frozen_string_literal: true

require 'tempfile'
require 'English'
require 'puppetfile-resolver/util'
require 'puppetfile-resolver/spec_searchers/common'
require 'puppetfile-resolver/spec_searchers/git_configuration'
require 'puppetfile-resolver/util'
require 'uri'

module PuppetfileResolver
  module SpecSearchers
    module Git
      module GClone
        METADATA_FILE = 'metadata.json'

        # @summary clones the remote url and reads the metadata file
        # @returns [String] the content of the metadata file
        def self.metadata(puppetfile_module, resolver_ui, config)
          repo_url = puppetfile_module.remote

          unless PuppetfileResolver::Util.git?
            resolver_ui.debug { 'Git executible not found, unable to use git clone resolution' }

            return nil
          end
          return nil if repo_url.nil?
          return nil unless valid_http_url?(repo_url)

          ref = puppetfile_module.ref ||
                puppetfile_module.tag ||
                puppetfile_module.commit ||
                puppetfile_module.branch ||
                'HEAD'

          resolver_ui.debug { "Querying git repository #{repo_url}" }

          clone_and_read_file(repo_url, ref, config)
        end

        # @summary clones the git url and reads the file at the given ref
        #          a temp directory will be created and then destroyed during
        #          the cloning and reading process
        # @param ref [String] the git ref, branch, commit, tag
        # @param file [String] the file you wish to read
        # @returns [String] the content of the file
        def self.clone_and_read_file(url, ref, config)
          Dir.mktmpdir(nil, config.clone_dir) do |dir|
            clone = ['git', 'clone', url, dir]
            clone += ['--config', "http.proxy=#{config.proxy}", '--config', "https.proxy=#{config.proxy}"] if config.proxy

            bare_clone = clone + ['--bare', '--depth=1']
            bare_clone.push("--branch=#{ref}") unless ref == 'HEAD'

            # Try to clone a bare repository. If that fails, fall back to a full clone.
            # Cloning might fail because the repo does not exist or is otherwise
            # inaccessible, but it can also fail because cloning a bare repository from
            # a commit/SHA1 fails. Falling back to a full clone ensures that we support
            # commits/SHA1s like Puppetfile does.
            _stdout, _stderr, process = ::PuppetfileResolver::Util.run_command(bare_clone)

            unless process.success?
              _stdout, stderr, process = ::PuppetfileResolver::Util.run_command(clone)

              unless process.success?
                msg = if config.proxy
                        "Cloning #{url} with proxy #{config.proxy} failed: #{stderr}"
                      else
                        "Cloning #{url} failed: #{stderr}"
                      end
                raise msg
              end
            end

            Dir.chdir(dir) do
              content, stderr, process = ::PuppetfileResolver::Util.run_command(['git', 'show', "#{ref}:#{METADATA_FILE}"])
              raise "Could not find #{METADATA_FILE} for ref #{ref} at #{url}: #{stderr}" unless process.success?
              return content
            end
          end
        end

        def self.valid_http_url?(url)
          # uri does not work with git urls, return true
          return true if url.start_with?('git@')

          uri = URI.parse(url)
          uri.is_a?(URI::HTTP) && !uri.host.nil?
        rescue URI::InvalidURIError
          false
        end
      end
    end
  end
end
