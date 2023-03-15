# frozen_string_literal: true

require 'open3'

module PuppetfileResolver
  module Util
    def self.symbolise_object(object)
      case # rubocop:disable Style/EmptyCaseCondition Ignore
      when object.is_a?(Hash)
        object.inject({}) do |memo, (k, v)| # rubocop:disable Style/EachWithObject Ignore
          memo[k.to_sym] = symbolise_object(v)
          memo
        end
      when object.is_a?(Array)
        object.map { |i| symbolise_object(i) }
      else
        object
      end
    end

    def self.static_ca_cert_file
      @static_ca_cert_file ||= File.expand_path(File.join(__dir__, 'data', 'ruby_ca_certs.pem'))
    end

    # Execute a HTTP/S GET query and return the response
    # @param [String, URI] uri The URI to request
    # @param [nil, String, URI] proxy The URI of the proxy server to use. Defaults to nil (No proxy server)
    # @return [Net::HTTPResponse] the response of the request
    def self.net_http_get(uri, proxy = nil)
      uri = URI.parse(uri) unless uri.is_a?(URI)

      http_options = { :use_ssl => uri.class == URI::HTTPS }
      # Because on Windows Ruby doesn't use the Windows certificate store which has up-to date
      # CA certs, we can't depend on someone setting the environment variable correctly. So use our
      # static CA PEM file if SSL_CERT_FILE is not set.
      http_options[:ca_file] = PuppetfileResolver::Util.static_ca_cert_file if ENV['SSL_CERT_FILE'].nil?

      start_args = [uri.host, uri.port]

      unless proxy.nil?
        proxy = URI.parse(proxy) unless proxy.is_a?(URI)
        start_args.concat([proxy.host, proxy.port, proxy.user, proxy.password])
      end

      Net::HTTP.start(*start_args, http_options) { |http| return http.request(Net::HTTP::Get.new(uri)) }
      nil
    end

    # @summary runs the command on the shell
    # @param cmd [Array] an array of command and args
    # @returns [Array] the result of running the comand and the process
    # @example run_command(['git', '--version'])
    def self.run_command(cmd)
      Open3.capture3(*cmd)
    end

    # @summary checks if git is installed and on the path
    # @returns [Boolean] true if git is found in the path
    def self.git?
      Open3.capture3('git', '--version')
      true
    rescue Errno::ENOENT
      false
    end
  end
end
