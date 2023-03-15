# frozen_string_literal: true

require 'puppetfile-resolver/models/module_dependency'
require 'puppetfile-resolver/models/puppet_dependency'
require 'puppetfile-resolver/puppetfile'

module PuppetfileResolver
  module Models
    class ModuleSpecification
      attr_accessor :name
      attr_accessor :owner
      attr_accessor :version
      attr_accessor :origin # Same as R10K module :type
      attr_accessor :resolver_flags

      def initialize(options = {})
        require 'semantic_puppet'

        @name = options[:name]
        @owner = options[:owner]
        # Munge the name
        # "puppetlabs/stdlib"
        # "puppetlabs-stdlib"
        # "puppetlabs-stdlib-1.0.0  ??"
        # "stdlib"
        unless @name.nil?
          result = @name.split('/', 2)
          if result.count > 1
            @owner = result[0]
            @name = result[1]
          else
            result = @name.split('-')
            if result.count > 1
              @owner = result[0]
              @name = result[1]
            end
          end
        end
        @origin = options[:origin]
        @dependencies = nil
        @metadata = options[:metadata]
        @resolver_flags = options[:resolver_flags].nil? ? [] : options[:resolver_flags]
        @version = ::SemanticPuppet::Version.parse(options[:version]) unless options[:version].nil?
      end

      def to_s
        prefix = case @origin
                 when :forge
                   'Forge'
                 when :git
                   'Git'
                 when :local
                   'Local'
                 else
                   'Unknown'
                 end
        "#{prefix} #{owner}-#{name}-#{version}"
      end

      def to_json(*args)
        {
          'name'    => name,
          'owner'   => owner,
          'origin'  => origin,
          'version' => version.to_s
        }.to_json(args)
      end

      def from_hash!(hash)
        @name = hash['name']
        @owner = hash['owner']
        @origin = hash['origin']
        @version = ::SemanticPuppet::Version.parse(hash['version']) unless hash['version'].nil?
        self
      end

      def metadata(_cache, _resolver_ui)
        # TODO: Later on we could resolve the metadata lazily, but for now, no need
        @metadata
      end

      def dependencies(cache, resolver_ui)
        return @dependencies unless @dependencies.nil?

        return (@dependencies = []) if resolver_flags.include?(PuppetfileResolver::Puppetfile::DISABLE_ALL_DEPENDENCIES_FLAG)

        meta = metadata(cache, resolver_ui)
        @dependencies = []
        unless meta[:dependencies].nil? || meta[:dependencies].empty?
          @dependencies = meta[:dependencies].map do |dep|
            ModuleDependency.new(
              name: dep[:name],
              version_requirement: dep[:version_requirement] || dep[:version_range] || '>= 0.0.0'
            )
          end
        end

        unless resolver_flags.include?(PuppetfileResolver::Puppetfile::DISABLE_PUPPET_DEPENDENCY_FLAG)
          puppet_requirement = nil
          unless meta[:requirements].nil? || meta[:requirements].empty? # rubocop:disable Style/IfUnlessModifier
            puppet_requirement = meta[:requirements].find { |req| req[:name] == 'puppet' && !req[:version_requirement].nil? }
          end
          if puppet_requirement.nil?
            @dependencies << PuppetDependency.new('>= 0')
          else
            @dependencies << PuppetDependency.new(puppet_requirement[:version_requirement])
          end
        end

        @dependencies
      end
    end
  end
end
