module PuppetLanguageServer
  module UriHelper
    def self.build_file_uri(path)
      path.start_with?('/') ? 'file://' + path : 'file:///' + path
    end
  end
end
