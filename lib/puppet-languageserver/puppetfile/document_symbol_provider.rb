module PuppetLanguageServer
  module Puppetfile
    module DocumentSymbolProvider
      def self.max_line_length
        # TODO: ... need to figure out the actual line length
        1000
      end

      # def self.workspace_symbols(query)
      #   query = '' if query.nil?
      #   result = []
      #   result
      # end

      def self.extract_document_symbols(content)
        symbols = []

        puppetfile = nil
        begin
          puppetfile = PuppetLanguageServer::Puppetfile::R10K::Puppetfile.new
          puppetfile.load!(content)
        rescue StandardError, SyntaxError, LoadError => _detail
          return symbols
        end
        return symbols if puppetfile.nil?

        puppetfile.modules.each do |mod|
          next if mod.properties[:type] == :invalid

          symbols.push(LanguageServer::DocumentSymbol.create(
            'name'           => mod.name,
            'kind'           => LanguageServer::SYMBOLKIND_FILE,
            'detail'         => mod.title,
            'range'          => [mod.puppetfile_line_number, 0, mod.puppetfile_line_number, max_line_length],
            'selectionRange' => [mod.puppetfile_line_number, 0, mod.puppetfile_line_number, max_line_length],
            'children'       => []
          ))
        end

        symbols
      end
    end
  end
end
