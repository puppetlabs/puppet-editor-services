# frozen_string_literal: true

module PuppetLanguageServer
  module ServerCapabilites
    def self.capabilities
      # https://github.com/Microsoft/language-server-protocol/blob/master/protocol.md#initialize-request

      result = {
        'textDocumentSync'        => LSP::TextDocumentSyncKind::FULL,
        'hoverProvider'           => true,
        'completionProvider'      => {
          'resolveProvider'   => true,
          'triggerCharacters' => ['>', '$', '[', '=']
        },
        'definitionProvider'      => true,
        'documentSymbolProvider'  => true,
        'workspaceSymbolProvider' => true,
        'signatureHelpProvider'   => {
          'triggerCharacters' => ['(', ',']
        }
      }
      result[:documentOnTypeFormattingProvider] = { 'firstTriggerCharacter' => '>' } if PuppetLanguageServer.featureflag?('hashrocket')

      result
    end

    def self.no_capabilities
      # Any empty hash denotes no capabilities at all
      {
      }
    end
  end
end
