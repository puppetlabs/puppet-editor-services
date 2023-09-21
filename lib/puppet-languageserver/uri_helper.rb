# frozen_string_literal: true

require 'uri'
require 'puppet'

module PuppetLanguageServer
  module UriHelper
    def self.build_file_uri(path)
      if path.nil?
        nil
      else
        "file://#{Puppet::Util.uri_encode(path.start_with?('/') ? path : "/#{path}")}"
      end
    end

    def self.uri_path(uri_string)
      uri_string.nil? ? nil : Puppet::Util.uri_to_path(URI(uri_string))
    end

    # Compares two URIs and returns the relative path
    #
    # @param root_uri [String] The root URI to compare to
    # @param uri [String] The URI to compare to the root
    # @param case_sensitive [Boolean] Whether the path comparison is case senstive or not.  Default is true
    # @return [String] Returns the relative path string if the URI is indeed a child of the root, otherwise returns nil
    def self.relative_uri_path(root_uri, uri, case_sensitive = true)
      actual_root = URI(root_uri)
      actual_uri = URI(uri)
      return nil unless actual_root.scheme == actual_uri.scheme

      # CGI.unescape doesn't handle space rules properly in uri paths
      # URI::parser.unescape does, but returns strings in their original encoding
      # Mostly safe here as we're only worried about file based URIs
      parser = URI::Parser.new
      root_path = parser.unescape(actual_root.path)
      uri_path = parser.unescape(actual_uri.path)
      if case_sensitive
        return nil unless uri_path.slice(0, root_path.length) == root_path
      else
        return nil unless uri_path.slice(0, root_path.length).casecmp(root_path).zero?
      end

      uri_path.slice(root_path.length..-1)
    end
  end
end
