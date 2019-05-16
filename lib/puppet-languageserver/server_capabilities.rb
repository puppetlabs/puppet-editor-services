# frozen_string_literal: true

module PuppetLanguageServer
  module ServerCapabilites
    def self.capabilities
      # https://github.com/Microsoft/language-server-protocol/blob/master/protocol.md#initialize-request

      {
        'textDocumentSync'        => LSP::TextDocumentSyncKind::FULL,
        'hoverProvider'           => true,
        'completionProvider'      => {
          'resolveProvider'   => true,
          'triggerCharacters' => ['>', '$', '[', '=']
        },
        'definitionProvider'      => true,
        'documentSymbolProvider'  => true,
        'workspaceSymbolProvider' => true
      }
    end
  end
end
