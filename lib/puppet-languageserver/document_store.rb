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
  end
end
