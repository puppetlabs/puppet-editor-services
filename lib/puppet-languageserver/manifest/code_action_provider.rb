module PuppetLanguageServer
  module Manifest
    module CodeActionProvider
      def self.provide_actions(code_action_request)
        # We only provide actions on diagnostics
        return nil if code_action_request['context']['diagnostics'].empty?
        file_uri = code_action_request['textDocument']['uri']
        content = PuppetLanguageServer::DocumentStore.document(file_uri)
        # We only providea actions on files that are being edited
        return nil if content.nil?
        content_version = PuppetLanguageServer::DocumentStore.document_version(file_uri)
        # Extract the per line information
        content_lines = content.lines

        result = []
        code_action_request['context']['diagnostics'].each do |diag|
          text_change = " # lint:ignore:#{diag['code']}"
          diag_start_line = diag['range']['start']['line']
          result << LanguageServer::CodeAction.create(
            'title'       => " Ignore '#{diag['message']}'",
            'edit'        => {
              'documentChanges' => [{
                'textDocument' => {
                  'uri'     => file_uri,
                  'version' => content_version
                },
                'edits'        => [
                  {
                    'range'   => {
                      'start' => { 'line' => diag_start_line, 'character' => line_length(content_lines, diag_start_line) },
                      'end'   => { 'line' => diag_start_line, 'character' => line_length(content_lines, diag_start_line) + 1 }
                    },
                    'newText' => text_change
                  }
                ]
              }]
            },
            'kind'        => LanguageServer::CODEACTIONKIND_REFACTORINLINE,
            'diagnostics' => [diag]
          )
        end

        result
      end

      def self.line_length(content_lines, line_number)
        content_lines[line_number].chomp.length
      end
    end
  end
end
