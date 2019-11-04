# frozen_string_literal: true

module PuppetfileResolver
  module Models
    class PuppetSpecification
      attr_reader :name
      attr_accessor :version

      def initialize(version)
        require 'semantic_puppet'

        @name = 'Puppet'
        @version = version.nil? ? nil : ::SemanticPuppet::Version.parse(version)
      end

      def to_s
        @version.nil? ? name.to_s : "#{name}-#{version}"
      end

      def dependencies(*_)
        []
      end
    end
  end
end
