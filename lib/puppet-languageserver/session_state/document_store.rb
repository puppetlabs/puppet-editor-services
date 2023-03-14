# frozen_string_literal: true

module PuppetLanguageServer
  module SessionState
    # Represents a Document in the Document Store.
    # Can be subclassed to add additional methods and helpers
    class Document
      attr_reader :uri, :content, :version, :tokens

      # @param uri String The content of the document
      # @param content String The content of the document
      # @param version Integer The version the document
      def initialize(uri, content, version)
        @uri = uri
        @content = content
        @version = version
        @tokens = nil
      end

      # Update a document with new content and version
      # @param content String The new content for the document
      # @param version Integer The version of the new document
      def update(content, version)
        @content = content
        @version = version
        @tokens = nil
      end

      # Subclass this!
      def calculate_tokens!
        []
      end
    end

    class EppDocument < Document; end

    class ManifestDocument < Document
      def calculate_tokens!
        lexer = Puppet::Pops::Parser::Lexer2WithComments.new
        lexer.lex_string(content)
        @tokens = lexer.fullscan
      end
    end

    class PuppetfileDocument < Document; end

    class DocumentStore
      # @param options :workspace Path to the workspace
      def initialize(_options = {})
        @documents = {}
        @doc_mutex = Mutex.new

        initialize_store
      end

      def set_document(uri, content, doc_version)
        @doc_mutex.synchronize do
          if @documents[uri].nil?
            @documents[uri] = create_document(uri, content, doc_version)
          else
            @documents[uri].update(content, doc_version)
          end
        end
      end

      def remove_document(uri)
        @doc_mutex.synchronize { @documents.delete(uri) }
        nil
      end

      def clear
        @doc_mutex.synchronize { @documents.clear }
      end

      def document(uri, doc_version = nil)
        @doc_mutex.synchronize do
          return nil if @documents[uri].nil?
          return nil unless doc_version.nil? || @documents[uri].version == doc_version
          @documents[uri]
        end
      end

      def document_content(uri, doc_version = nil)
        doc = document(uri, doc_version)
        doc.nil? ? nil : doc.content.clone
      end

      def document_tokens(uri, doc_version = nil)
        @doc_mutex.synchronize do
          return nil if @documents[uri].nil?
          return nil unless doc_version.nil? || @documents[uri].version == doc_version
          return @documents[uri].tokens unless @documents[uri].tokens.nil?
          return @documents[uri].calculate_tokens!
        end
      end

      def document_version(uri)
        doc = document(uri)
        doc.nil? ? nil : doc.version
      end

      def document_uris
        @doc_mutex.synchronize { @documents.keys.dup }
      end

      def document_type(uri)
        case uri
        when /\/Puppetfile$/i
          :puppetfile
        when /\.pp$/i
          :manifest
        when /\.epp$/i
          :epp
        else
          :unknown
        end
      end

      # Plan files https://puppet.com/docs/bolt/1.x/writing_plans.html#concept-4485 can exist in many places
      # The current best detection method is as follows:
      # "Given the full path to the .pp file, if it contains a directory called plans, AND that plans is not a sub-directory of manifests, then it is a plan file"
      #
      # See https://github.com/lingua-pupuli/puppet-editor-services/issues/129 for the full discussion
      def plan_file?(uri)
        uri_path = PuppetLanguageServer::UriHelper.uri_path(uri)
        return false if uri_path.nil?
        # For the text searching below we need a leading slash. That way
        # we don't need to use regexes which is slower
        uri_path = "/#{uri_path}" unless uri_path.start_with?('/')
        if windows?
          plans_index = uri_path.upcase.index('/PLANS/')
          manifests_index = uri_path.upcase.index('/MANIFESTS/')
        else
          plans_index = uri_path.index('/plans/')
          manifests_index = uri_path.index('/manifests/')
        end
        return false if plans_index.nil?
        return true if manifests_index.nil?

        plans_index < manifests_index
      end

      # Workspace management
      WORKSPACE_CACHE_TTL_SECONDS ||= 60
      def initialize_store(options = {})
        @workspace_path = options[:workspace]
        @workspace_info_cache = {
          :expires => Time.new - 120
        }
      end

      def expire_store_information
        @doc_mutex.synchronize do
          @workspace_info_cache[:expires] = Time.new - 120
        end
      end

      def store_root_path
        store_details[:root_path]
      end

      def store_has_module_metadata?
        store_details[:has_metadatajson]
      end

      def store_has_environmentconf?
        store_details[:has_environmentconf]
      end

      private

      # Given a path, locate a metadata.json or environment.conf file to determine where the
      # root of the module/control repo actually is
      def find_root_path(path)
        return nil if path.nil?
        filepath = File.expand_path(path)

        if dir_exist?(filepath)
          directory = filepath
        elsif file_exist?(filepath)
          directory = File.dirname(filepath)
        else
          return nil
        end

        until directory.nil?
          break if file_exist?(File.join(directory, 'metadata.json')) || file_exist?(File.join(directory, 'environment.conf'))
          parent = File.dirname(directory)
          # If the parent is the same as the original, then we've reached the end of the path chain
          if parent == directory
            directory = nil
          else
            directory = parent
          end
        end

        directory
      end

      def store_details
        return @workspace_info_cache unless @workspace_info_cache[:never_expires] || @workspace_info_cache[:expires] < Time.new
        # TTL has expired, time to calculate the document store details

        new_cache = {
          :root_path           => nil,
          :has_environmentconf => false,
          :has_metadatajson    => false
        }
        if @workspace_path.nil?
          # If we have never been given a local workspace path on the command line then there is really no
          # way to know where the module file system path is.  Therefore the root_path is nil and assume that
          # environment.conf and metadata.json does not exist. And don't bother trying to re-evaluate
          new_cache[:never_expires] = true
        else
          root_path = find_root_path(@workspace_path)
          if root_path.nil?
            new_cache[:root_path] = @workspace_path
          else
            new_cache[:root_path] = root_path
            new_cache[:has_metadatajson] = file_exist?(File.join(root_path, 'metadata.json'))
            new_cache[:has_environmentconf] = file_exist?(File.join(root_path, 'environment.conf'))
          end
        end
        new_cache[:expires] = Time.new + WORKSPACE_CACHE_TTL_SECONDS

        @doc_mutex.synchronize do
          @workspace_info_cache = new_cache
        end
        @workspace_info_cache
      end

      def file_exist?(path)
        File.exist?(path) && !File.directory?(path)
      end

      def dir_exist?(path)
        Dir.exist?(path)
      end

      def windows?
        # Ruby only sets File::ALT_SEPARATOR on Windows and the Ruby standard
        # library uses that to test what platform it's on.
        !!File::ALT_SEPARATOR # rubocop:disable Style/DoubleNegation
      end

      # Creates a document object based on the Uri
      def create_document(uri, content, doc_version)
        case document_type(uri)
        when :puppetfile
          PuppetfileDocument.new(uri, content, doc_version)
        when :manifest
          ManifestDocument.new(uri, content, doc_version)
        when :epp
          EppDocument.new(uri, content, doc_version)
        else
          Document.new(uri, content, doc_version)
        end
      end
    end
  end
end
