module PuppetLanguageServer
  module DocumentStore
    @documents = {}
    @doc_mutex = Mutex.new

    def self.set_document(uri, content, doc_version)
      @doc_mutex.synchronize do
        @documents[uri] = {
          :content => content,
          :version => doc_version
        }
      end
    end

    def self.remove_document(uri)
      @doc_mutex.synchronize { @documents[uri] = nil }
    end

    def self.clear
      @doc_mutex.synchronize { @documents.clear }
    end

    def self.document(uri, doc_version = nil)
      @doc_mutex.synchronize do
        return nil if @documents[uri].nil?
        return nil unless doc_version.nil? || @documents[uri][:version] == doc_version
        @documents[uri][:content].clone
      end
    end

    def self.document_version(uri)
      @doc_mutex.synchronize do
        return nil if @documents[uri].nil?
        @documents[uri][:version]
      end
    end

    def self.document_uris
      @doc_mutex.synchronize { @documents.keys.dup }
    end

    def self.document_type(uri)
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

    # Workspace management
    WORKSPACE_CACHE_TTL_SECONDS = 60
    def self.initialize_store(options = {})
      @workspace_path = options[:workspace]
      @workspace_info_cache = {
        :expires => Time.new - 120
      }
    end

    # This method is mainly used for testin. It expires the cache
    def self.expire_store_information
      @doc_mutex.synchronize do
        @workspace_info_cache[:expires] = Time.new - 120
      end
    end

    def self.store_root_path
      store_details[:root_path]
    end

    def self.store_has_module_metadata?
      store_details[:has_metadatajson]
    end

    def self.store_has_puppetfile?
      store_details[:has_puppetfile]
    end

    # Given a path, locate a metadata.json or Puppetfile file to determine where the
    # root of the module/control repo actually is
    def self.find_root_path(path)
      return nil if path.nil?

      filepath = Pathname.new(path).expand_path
      return nil unless filepath.exist?

      if filepath.directory?
        directory = filepath
      else
        directory = filepath.dirname
      end

      root_path = nil
      directory.ascend do |p|
        if file_exist?(p.join('metadata.json')) || file_exist?(p.join('Puppetfile'))
          root_path = p.to_s
          break
        end
      end

      root_path
    end
    private_class_method :find_root_path

    def self.store_details
      return @workspace_info_cache unless @workspace_info_cache[:never_expires] || @workspace_info_cache[:expires] < Time.new
      # TTL has expired, time to calculate the document store details

      new_cache = {
        :root_path => nil,
        :has_puppetfile => false,
        :has_metadatajson => false
      }
      if @workspace_path.nil?
        # If we have never been given a local workspace path on the command line then there is really no
        # way to know where the module file system path is.  Therefore the root_path is nil and assume that
        # puppetfile and metadata.json does not exist. And don't bother trying to re-evaluate
        new_cache[:never_expires] = true
      else
        root_path = find_root_path(@workspace_path)
        if root_path.nil?
          new_cache[:root_path] = @workspace_path
        else
          new_cache[:root_path] = root_path
          new_cache[:has_metadatajson] = file_exist?(File.join(root_path, 'metadata.json'))
          new_cache[:has_puppetfile] = file_exist?(File.join(root_path, 'Puppetfile'))
        end
      end
      new_cache[:expires] = Time.new + WORKSPACE_CACHE_TTL_SECONDS

      @doc_mutex.synchronize do
        @workspace_info_cache = new_cache
      end
      @workspace_info_cache
    end
    private_class_method :store_details

    def self.file_exist?(path)
      File.exist?(path)
    end
    private_class_method :file_exist?
  end
end
