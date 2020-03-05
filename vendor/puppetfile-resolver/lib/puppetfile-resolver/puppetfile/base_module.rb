# frozen_string_literal: true

module PuppetfileResolver
  module Puppetfile
    FORGE_MODULE   = :forge
    GIT_MODULE     = :git
    INVALID_MODULE = :invalid
    LOCAL_MODULE   = :local
    SVN_MODULE     = :svn

    class BaseModule
      # The full title of the module
      attr_accessor :title

      # The owner of the module
      attr_accessor :owner

      # The name of the module
      attr_accessor :name

      # The version of the module
      attr_accessor :version

      # The location of the module instantiation in the Puppetfile document
      # [DocumentLocation]
      attr_accessor :location

      attr_reader :module_type

      # Array of flags that will instruct the resolver to change its default behaviour. Current flags are
      # set out in the PuppetfileResolver::Puppetfile::..._FLAG constants
      # @api private
      # @return [Array[Symbol]] Array of flags that will instruct the resolver to change its default behaviour
      attr_accessor :resolver_flags

      def initialize(title)
        @title = title
        unless title.nil? # rubocop:disable Style/IfUnlessModifier
          @owner, @name = parse_title(@title)
        end
        @location = DocumentLocation.new
        @resolver_flags = []
      end

      def to_s
        "#{self.class} #{title}-#{name}"
      end

      private

      def parse_title(title)
        if (match = title.match(/\A(\w+)\Z/))
          [nil, match[1]]
        elsif (match = title.match(/\A(\w+)[-\/](\w+)\Z/))
          [match[1], match[2]]
        else
          raise ArgumentError, format("Module name (%<title>s) must match either 'modulename' or 'owner/modulename'", title: title)
        end
      end
    end
  end
end
