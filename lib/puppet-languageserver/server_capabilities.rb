# frozen_string_literal: true

require 'lsp/lsp'

module PuppetLanguageServer
  module ServerCapabilites
    def self.capabilities(options = {})
      # https://github.com/Microsoft/language-server-protocol/blob/master/protocol.md#initialize-request

      value = {
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
      value['documentOnTypeFormattingProvider'] = document_on_type_formatting_options if options[:documentOnTypeFormattingProvider]
      value
    end

    def self.document_on_type_formatting_options
      {
        'firstTriggerCharacter' => '>'
      }
    end

    def self.no_capabilities
      # Any empty hash denotes no capabilities at all
      {
      }
    end
  end
end
