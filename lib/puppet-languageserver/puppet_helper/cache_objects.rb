# frozen_string_literal: true

module PuppetLanguageServer
  module PuppetHelper
    module CacheExtensions
      # origin is used to store where this cache entry came from, for example, workspace or
      # default environment
      attr_accessor :origin

      def from_sidecar!(value)
        (value.class.instance_methods - Object.instance_methods).reject { |name| name.to_s.end_with?('=') || name.to_s.end_with?('!') }
                                                                .reject { |name| %i[to_h to_json].include?(name) }
                                                                .each do |method_name|
          send("#{method_name}=", value.send(method_name))
        end
        self
      end
    end

    class PuppetClass < PuppetLanguageServer::Sidecar::Protocol::PuppetClass
      include CacheExtensions
    end

    class PuppetFunction < PuppetLanguageServer::Sidecar::Protocol::PuppetFunction
      include CacheExtensions
    end

    class PuppetType < PuppetLanguageServer::Sidecar::Protocol::PuppetType
      include CacheExtensions

      def allattrs
        @attributes.keys
      end

      def parameters
        @attributes.select { |_name, data| data[:type] == :param }
      end

      def properties
        @attributes.select { |_name, data| data[:type] == :property }
      end

      def meta_parameters
        @attributes.select { |_name, data| data[:type] == :meta }
      end
    end
  end
end
