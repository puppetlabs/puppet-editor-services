# frozen_string_literal: true

module PuppetfileResolver
  module Puppetfile
    # Resolver Flags
    #
    # DISABLE_PUPPET_DEPENDENCY_FLAG - Instructs the resolver to not consider Puppet version in its dependency traversal. Useful for modules with outdated metadata.json information.
    # DISABLE_ALL_DEPENDENCIES_FLAG - Instructs the resolver to ignore any dependencies in its dependency traversal. Useful for modules with outdated metadata.json information.
    # DISABLE_LATEST_VALIDATION_FLAG - Instructs the resolution validator to ignore modules that have a version of :latest
    #
    DISABLE_PUPPET_DEPENDENCY_FLAG = :disable_puppet_dependency
    DISABLE_ALL_DEPENDENCIES_FLAG = :disable_all_dependencies
    DISABLE_LATEST_VALIDATION_FLAG = :disable_latest_validation
  end
end

require 'puppetfile-resolver/puppetfile/document'
require 'puppetfile-resolver/puppetfile/validation_errors'
require 'puppetfile-resolver/puppetfile/base_module'
require 'puppetfile-resolver/puppetfile/forge_module'
require 'puppetfile-resolver/puppetfile/git_module'
require 'puppetfile-resolver/puppetfile/invalid_module'
require 'puppetfile-resolver/puppetfile/local_module'
require 'puppetfile-resolver/puppetfile/svn_module'
require 'puppetfile-resolver/puppetfile/parser/r10k_eval'
