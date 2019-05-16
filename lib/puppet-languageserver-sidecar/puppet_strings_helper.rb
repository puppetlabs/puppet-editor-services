# frozen_string_literal: true

module PuppetLanguageServerSidecar
  module PuppetStringsHelper
    # Returns a FileDocumentation object for a given path
    #
    # @param [String] path The absolute path to the file that will be documented
    # @return [FileDocumentation, nil] Returns the documentation for the path, or nil if it cannot be extracted
    def self.file_documentation(path)
      return nil unless require_puppet_strings
      @helper_cache = FileDocumentationCache.new if @helper_cache.nil?
      return @helper_cache.document(path) if @helper_cache.path_exists?(path)
      PuppetLanguageServerSidecar.log_message(:debug, "[PuppetStringsHelper::file_documentation] Fetching documentation for #{path}")

      setup_yard!

      # For now, assume a single file path
      search_patterns = [path]

      # Format the arguments to YARD
      args = ['doc']
      args << '--no-output'
      args << '--quiet'
      args << '--no-stats'
      args << '--no-progress'
      args << '--no-save'
      args << '--api public'
      args << '--api private'
      args << '--no-api'
      args += search_patterns

      # Run YARD
      ::YARD::CLI::Yardoc.run(*args)

      # Populate the documentation cache from the YARD information
      @helper_cache.populate_from_yard_registry!

      # Return the documentation details
      @helper_cache.document(path)
    end

    def self.require_puppet_strings
      return @puppet_strings_loaded unless @puppet_strings_loaded.nil?
      begin
        require 'puppet-strings'
        require 'puppet-strings/yard'
        require 'puppet-strings/json'

        require File.expand_path(File.join(File.dirname(__FILE__), 'puppet_strings_monkey_patches'))
        @puppet_strings_loaded = true
      rescue LoadError => e
        PuppetLanguageServerSidecar.log_message(:error, "[PuppetStringsHelper::require_puppet_strings] Unable to load puppet-strings gem: #{e}")
        @puppet_strings_loaded = false
      end
      @puppet_strings_loaded
    end
    private_class_method :require_puppet_strings

    def self.setup_yard!
      unless @yard_setup # rubocop:disable Style/GuardClause
        ::PuppetStrings::Yard.setup!
        @yard_setup = true
      end
    end
    private_class_method :setup_yard!
  end

  class FileDocumentationCache
    def initialize
      # Hash of <[String] path, FileDocumentation> objects
      @cache = {}
    end

    def path_exists?(path)
      @cache.key?(path)
    end

    def document(path)
      @cache[path]
    end

    def populate_from_yard_registry!
      # Extract all of the information
      # Ref - https://github.com/puppetlabs/puppet-strings/blob/87a8e10f45bfeb7b6b8e766324bfb126de59f791/lib/puppet-strings/json.rb#L10-L16
      populate_functions_from_yard_registry!
      populate_types_from_yard_registry!
    end

    private

    def populate_functions_from_yard_registry!
      ::YARD::Registry.all(:puppet_function).map(&:to_hash).each do |item|
        source_path = item[:file]
        func_name = item[:name].to_s
        @cache[source_path] = FileDocumentation.new(source_path) if @cache[source_path].nil?

        obj                  = PuppetLanguageServer::Sidecar::Protocol::PuppetFunction.new
        obj.key              = func_name
        obj.source           = item[:file]
        obj.calling_source   = obj.source
        obj.line             = item[:line]
        obj.doc              = item[:docstring][:text]
        obj.arity            = -1 # We don't care about arity
        obj.function_version = item[:type] == 'ruby4x' ? 4 : 3

        # Try and determine the function call site from the source file
        char = item[:source].index(":#{func_name}")
        unless char.nil?
          obj.char = char
          obj.length = func_name.length + 1
        end

        case item[:type]
        when 'ruby3x'
          obj.function_version = 3
          # This is a bit hacky but it works (probably).  Puppet-Strings doesn't rip this information out, but you do have the
          # the source to query
          obj.type = item[:source].match(/:rvalue/) ? :rvalue : :statement
        when 'ruby4x'
          obj.function_version = 4
          # All ruby functions are statements
          obj.type = :statement
        else
          PuppetLanguageServerSidecar.log_message(:error, "[#{self.class}] Unknown function type #{item[:type]}")
        end

        @cache[source_path].functions[func_name] = obj
      end
    end

    def populate_types_from_yard_registry!
      ::YARD::Registry.all(:puppet_type).map(&:to_hash).each do |item|
        source_path = item[:file]
        type_name = item[:name].to_s
        @cache[source_path] = FileDocumentation.new(source_path) if @cache[source_path].nil?

        obj                = PuppetLanguageServer::Sidecar::Protocol::PuppetType.new
        obj.key            = type_name
        obj.source         = item[:file]
        obj.calling_source = obj.source
        obj.line           = item[:line]
        obj.doc            = item[:docstring][:text]

        obj.attributes = {}
        item[:properties]&.each do |prop|
          obj.attributes[prop[:name]] = {
            :type => :property,
            :doc  => prop[:description]
          }
        end
        item[:parameters]&.each do |prop|
          obj.attributes[prop[:name]] = {
            :type       => :param,
            :doc        => prop[:description],
            :isnamevar? => prop[:isnamevar]
          }
        end

        @cache[source_path].types[type_name] = obj
      end
    end
  end

  class FileDocumentation
    # The path to file that has been documented
    attr_reader :path

    # Hash of <[String]Name, PuppetLanguageServer::Sidecar::Protocol::PuppetFunction> objects
    attr_accessor :functions

    # Hash of <[String]Name, PuppetLanguageServer::Sidecar::Protocol::PuppetType> objects
    attr_accessor :types

    def initialize(path)
      @path = path
      @functions = {}
      @types = {}
    end

    def fetch_function(func_name)
      @functions[func_name]
    end
  end
end
