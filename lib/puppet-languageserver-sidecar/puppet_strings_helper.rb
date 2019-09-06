# frozen_string_literal: true

module PuppetLanguageServerSidecar
  module PuppetStringsHelper
    def self.instance
      @instance ||= Helper.new
    end

    def self.file_documentation(path, cache = nil)
      instance.file_documentation(path, cache)
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

    def self.setup_yard!
      unless @yard_setup # rubocop:disable Style/GuardClause
        ::PuppetStrings::Yard.setup!
        @yard_setup = true
      end
    end

    class Helper
      # Returns a FileDocumentation object for a given path
      #
      # @param [String] path The absolute path to the file that will be documented
      # @param [PuppetLanguageServerSidecar::Cache] cache A Sidecar cache which stores already parsed documents as serialised FileDocumentation objects
      # @return [FileDocumentation, nil] Returns the documentation for the path, or nil if it cannot be extracted
      def file_documentation(path, cache = nil)
        return nil unless PuppetLanguageServerSidecar::PuppetStringsHelper.require_puppet_strings
        @helper_cache = FileDocumentationCache.new if @helper_cache.nil?
        return @helper_cache.document(path) if @helper_cache.path_exists?(path)

        # Load from the permanent cache
        @helper_cache.populate_from_sidecar_cache!(path, cache) unless cache.nil? || !cache.active?
        return @helper_cache.document(path) if @helper_cache.path_exists?(path)

        PuppetLanguageServerSidecar.log_message(:debug, "[PuppetStringsHelper::file_documentation] Fetching documentation for #{path}")

        PuppetLanguageServerSidecar::PuppetStringsHelper.setup_yard!

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

        # Save to the permanent cache
        @helper_cache.save_to_sidecar_cache(path, cache) unless cache.nil? || !cache.active?

        # Return the documentation details
        @helper_cache.document(path)
      end
    end
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
      populate_classes_from_yard_registry!
      populate_data_types_from_yard_registry!
      populate_functions_from_yard_registry!
      populate_types_from_yard_registry!
    end

    def populate_from_sidecar_cache!(path, cache)
      cached_result = cache.load(path, PuppetLanguageServerSidecar::Cache::PUPPETSTRINGS_SECTION)
      unless cached_result.nil? # rubocop:disable Style/GuardClause    Reads better this way
        begin
          obj = FileDocumentation.new.from_json!(cached_result)
          @cache[path] = obj
        rescue StandardError => e
          PuppetLanguageServerSidecar.log_message(:warn, "[FileDocumentationCache::populate_from_sidecar_cache!] Error while deserializing #{path} from cache: #{e}")
        end
      end
    end

    def save_to_sidecar_cache(path, cache)
      cache.save(path, PuppetLanguageServerSidecar::Cache::PUPPETSTRINGS_SECTION, document(path).to_json) if cache.active?
    end

    private

    def populate_classes_from_yard_registry!
      %I[puppet_class puppet_defined_type].each do |yard_type|
        YARD::Registry.all(yard_type).map(&:to_hash).each do |item|
          source_path = item[:file]
          class_name = item[:name].to_s
          @cache[source_path] = FileDocumentation.new(source_path) if @cache[source_path].nil?

          obj                = PuppetLanguageServer::Sidecar::Protocol::PuppetClass.new
          obj.key            = class_name
          obj.source         = item[:file]
          obj.calling_source = obj.source
          obj.line           = item[:line]

          obj.doc            = item[:docstring][:text]
          obj.parameters     = {}
          # Extract the class parameters
          item[:docstring][:tags]&.select { |tag| tag[:tag_name] == 'param' }&.each do |tag|
            param_name = tag[:name]
            obj.parameters[param_name] = {
              :doc  => tag[:text],
              :type => tag[:types].join(', ')
            }
          end

          @cache[source_path].classes << obj
        end
      end
    end

    def populate_data_types_from_yard_registry!
      ::YARD::Registry.all(:puppet_data_type).map(&:to_hash).each do |item|
        source_path = item[:file]
        type_name = item[:name].to_s
        @cache[source_path] = FileDocumentation.new(source_path) if @cache[source_path].nil?

        obj                = PuppetLanguageServer::Sidecar::Protocol::PuppetDataType.new
        obj.key            = type_name
        obj.source         = item[:file]
        obj.calling_source = obj.source
        obj.line           = item[:line]
        obj.doc            = item[:docstring][:text]
        obj.is_type_alias  = false
        obj.alias_of       = nil

        defaults = item[:defaults] || {}
        item[:docstring][:tags]&.select { |tag| tag[:tag_name] == 'param' }&.each do |tag|
          obj.attributes << PuppetLanguageServer::Sidecar::Protocol::PuppetDataTypeAttribute.new.from_h!(
            'key'           => tag[:name],
            'default_value' => defaults[tag[:name]],
            'doc'           => tag[:text],
            'types'         => tag[:types].nil? ? nil : tag[:types].join(', ')
          )
        end

        @cache[source_path].datatypes << obj
      end
      ::YARD::Registry.all(:puppet_data_type_alias).map(&:to_hash).each do |item|
        source_path = item[:file]
        type_name = item[:name].to_s
        @cache[source_path] = FileDocumentation.new(source_path) if @cache[source_path].nil?

        obj                = PuppetLanguageServer::Sidecar::Protocol::PuppetDataType.new
        obj.key            = type_name
        obj.source         = item[:file]
        obj.calling_source = obj.source
        obj.line           = item[:line]
        obj.doc            = item[:docstring][:text]
        obj.is_type_alias  = true
        obj.alias_of       = item[:alias_of]

        @cache[source_path].datatypes << obj
      end
    end

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
        # 'ruby3x' functions are version 3.  'ruby4x' and 'puppet' are version 4
        obj.function_version = item[:type] == 'ruby3x' ? 3 : 4

        # Try and determine the function call site from the source file
        char = item[:source].index(":#{func_name}")
        unless char.nil?
          obj.char = char
          obj.length = func_name.length + 1
        end

        # Note that puppet strings doesn't populate the method signatures for V3 functions
        # Also, we don't have access to the arity of V3 functions so we can't reverse engineer the signature
        item[:signatures].each do |signature|
          sig = PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionSignature.new

          sig.key = signature[:signature]
          sig.doc = signature[:docstring][:text]
          signature[:docstring][:tags].each do |tag|
            case tag[:tag_name]
            when 'param'
              sig.parameters << PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionSignatureParameter.new.from_h!(
                'name'  => tag[:name],
                'types' => tag[:types],
                'doc'   => tag[:text]
              )
            when 'return'
              sig.return_types = tag[:types]
            end
          end
          calculate_signature_parameter_locations!(sig)
          obj.signatures << sig
        end

        # Extract other common information
        # TODO: Other common tags include `example`, `overload`
        pre_docs = ''
        pre_docs += "This uses the legacy Ruby function API\n" if item[:type] == 'ruby3x'
        since_tag = item[:docstring][:tags].find { |tag| tag[:tag_name] == 'since' }
        pre_docs += "Since #{since_tag[:text]}\n" unless since_tag.nil?
        obj.doc = pre_docs + "\n" + obj.doc unless pre_docs.empty?

        @cache[source_path].functions << obj
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

        @cache[source_path].types << obj
      end
    end

    def calculate_signature_parameter_locations!(sig)
      # When Puppet Strings extracts the parameter name it differs from how it appears in the signature key
      # This makes it hard for clients to determine where in the signature, the parameter actually is.  So
      # We need to calculate where in the signature key a parameter is

      sig.parameters.each do |param|
        name = param.name.dup # Don't want to modify the original object
        # Munge the parameter name to what it appears in the signature key
        # Ref - https://github.com/puppetlabs/puppet-strings/blob/2987558bb3170bc37e6077aab1b60efb17161eff/lib/puppet-strings/yard/handlers/ruby/function_handler.rb#L293-L317
        if name.start_with?('*') || name.start_with?('&')
          name.insert(1, '$')
        else
          name = '$' + name
        end

        # We need to use terminating characters here due to substring matching e.g. $abc will incorrectly match in
        # function([String] $abc123, [String] $abc)
        idx = sig.key.index(name + ',')
        idx = sig.key.index(name + ')') if idx.nil?

        unless idx.nil?
          param.signature_key_offset = idx
          param.signature_key_length = name.length
        end
      end
    end
  end

  class FileDocumentation
    # The path to file that has been documented
    attr_accessor :path

    # PuppetLanguageServer::Sidecar::Protocol::PuppetClassList object holding all classes
    attr_accessor :classes

    # PuppetLanguageServer::Sidecar::Protocol::PuppetDataTypeList object holding all types
    attr_accessor :datatypes

    # PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionList object holding all functions
    attr_accessor :functions

    # PuppetLanguageServer::Sidecar::Protocol::PuppetTypeList object holding all types
    attr_accessor :types

    def initialize(path = nil)
      @path      = path
      @classes   = PuppetLanguageServer::Sidecar::Protocol::PuppetClassList.new
      @datatypes = PuppetLanguageServer::Sidecar::Protocol::PuppetDataTypeList.new
      @functions = PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionList.new
      @types     = PuppetLanguageServer::Sidecar::Protocol::PuppetTypeList.new
    end

    # Serialisation
    def to_h
      {
        'path'      => path,
        'classes'   => classes,
        'datatypes' => datatypes,
        'functions' => functions,
        'types'     => types
      }
    end

    def to_json(*options)
      JSON.generate(to_h, options)
    end

    # Deserialisation
    def from_json!(json_string)
      obj = JSON.parse(json_string)

      obj.keys.each do |key|
        case key
        when 'path'
          # Simple deserialised object types
          self.instance_variable_set("@#{key}", obj[key]) # rubocop:disable Style/RedundantSelf   Reads better this way
        else
          # Sidecar protocol list object types
          prop = self.instance_variable_get("@#{key}") # rubocop:disable Style/RedundantSelf   Reads better this way

          obj[key].each do |child_hash|
            child = prop.child_type.new
            # Let the sidecar deserialise for us
            prop << child.from_h!(child_hash)
          end
        end
      end
      self
    end
  end
end
