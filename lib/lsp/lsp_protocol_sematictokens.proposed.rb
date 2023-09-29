# frozen_string_literal: true

# DO NOT MODIFY. This file is built automatically
# LSP Protocol: vscode-languageserver-protocol/lib/protocol.sematicTokens.proposed.d.ts

# rubocop:disable Naming/MethodName

module LSP
  # export interface SemanticTokensLegend {
  #     /**
  #      * The token types a server uses.
  #      */
  #     tokenTypes: string[];
  #     /**
  #      * The token modifiers a server uses.
  #      */
  #     tokenModifiers: string[];
  # }
  class SemanticTokensLegend < LSPBase
    attr_accessor :tokenTypes, :tokenModifiers # type: string[] # type: string[]

    def from_h!(value)
      value = {} if value.nil?
      self.tokenTypes = value['tokenTypes'].map { |val| val } unless value['tokenTypes'].nil?
      self.tokenModifiers = value['tokenModifiers'].map { |val| val } unless value['tokenModifiers'].nil?
      self
    end
  end

  # export interface SemanticTokens {
  #     /**
  #      * An optional result id. If provided and clients support delta updating
  #      * the client will include the result id in the next semantic token request.
  #      * A server can then instead of computing all sematic tokens again simply
  #      * send a delta.
  #      */
  #     resultId?: string;
  #     /**
  #      * The actual tokens. For a detailed description about how the data is
  #      * structured pls see
  #      * https://github.com/microsoft/vscode-extension-samples/blob/5ae1f7787122812dcc84e37427ca90af5ee09f14/semantic-tokens-sample/vscode.proposed.d.ts#L71
  #      */
  #     data: number[];
  # }
  class SemanticTokens < LSPBase
    attr_accessor :resultId, :data # type: string # type: number[]

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[resultId]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.resultId = value['resultId']
      self.data = value['data'].map { |val| val } unless value['data'].nil?
      self
    end
  end

  # export interface SemanticTokensPartialResult {
  #     data: number[];
  # }
  class SemanticTokensPartialResult < LSPBase
    attr_accessor :data # type: number[]

    def from_h!(value)
      value = {} if value.nil?
      self.data = value['data'].map { |val| val } unless value['data'].nil?
      self
    end
  end

  # export interface SemanticTokensEdit {
  #     start: number;
  #     deleteCount: number;
  #     data?: number[];
  # }
  class SemanticTokensEdit < LSPBase
    attr_accessor :start, :deleteCount, :data # type: number # type: number # type: number[]

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[data]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.start = value['start']
      self.deleteCount = value['deleteCount']
      self.data = value['data'].map { |val| val } unless value['data'].nil?
      self
    end
  end

  # export interface SemanticTokensEdits {
  #     readonly resultId?: string;
  #     /**
  #      * For a detailed description how these edits are structured pls see
  #      * https://github.com/microsoft/vscode-extension-samples/blob/5ae1f7787122812dcc84e37427ca90af5ee09f14/semantic-tokens-sample/vscode.proposed.d.ts#L131
  #      */
  #     edits: SemanticTokensEdit[];
  # }
  class SemanticTokensEdits < LSPBase
    attr_accessor :resultId, :edits # type: string # type: SemanticTokensEdit[]

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[resultId]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.resultId = value['resultId']
      self.edits = to_typed_aray(value['edits'], SemanticTokensEdit)
      self
    end
  end

  # export interface SemanticTokensEditsPartialResult {
  #     edits: SemanticTokensEdit[];
  # }
  class SemanticTokensEditsPartialResult < LSPBase
    attr_accessor :edits # type: SemanticTokensEdit[]

    def from_h!(value)
      value = {} if value.nil?
      self.edits = to_typed_aray(value['edits'], SemanticTokensEdit)
      self
    end
  end

  # export interface SemanticTokensClientCapabilities {
  #     /**
  #      * The text document client capabilities
  #      */
  #     textDocument?: {
  #         /**
  #          * Capabilities specific to the `textDocument/semanticTokens`
  #          *
  #          * @since 3.16.0 - Proposed state
  #          */
  #         semanticTokens?: {
  #             /**
  #              * Whether implementation supports dynamic registration. If this is set to `true`
  #              * the client supports the new `(TextDocumentRegistrationOptions & StaticRegistrationOptions)`
  #              * return value for the corresponding server capability as well.
  #              */
  #             dynamicRegistration?: boolean;
  #             /**
  #              * The token types know by the client.
  #              */
  #             tokenTypes: string[];
  #             /**
  #              * The token modifiers know by the client.
  #              */
  #             tokenModifiers: string[];
  #         };
  #     };
  # }
  class SemanticTokensClientCapabilities < LSPBase
    attr_accessor :textDocument # type: {

    #        /**
    #         * Capabilities specific to the `textDocument/semanticTokens`
    #         *
    #         * @since 3.16.0 - Proposed state
    #         */
    #        semanticTokens?: {
    #            /**
    #             * Whether implementation supports dynamic registration. If this is set to `true`
    #             * the client supports the new `(TextDocumentRegistrationOptions & StaticRegistrationOptions)`
    #             * return value for the corresponding server capability as well.
    #             */
    #            dynamicRegistration?: boolean;
    #            /**
    #             * The token types know by the client.
    #             */
    #            tokenTypes: string[];
    #            /**
    #             * The token modifiers know by the client.
    #             */
    #            tokenModifiers: string[];
    #        };
    #    }

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[textDocument]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = value['textDocument'] # Unknown type
      self
    end
  end

  # export interface SemanticTokensOptions extends WorkDoneProgressOptions {
  #     /**
  #      * The legend used by the server
  #      */
  #     legend: SemanticTokensLegend;
  #     /**
  #      * Server supports providing semantic tokens for a sepcific range
  #      * of a document.
  #      */
  #     rangeProvider?: boolean;
  #     /**
  #      * Server supports providing semantic tokens for a full document.
  #      */
  #     documentProvider?: boolean | {
  #         /**
  #          * The server supports deltas for full documents.
  #          */
  #         edits?: boolean;
  #     };
  # }
  class SemanticTokensOptions < LSPBase
    attr_accessor :legend, :rangeProvider, :documentProvider # type: SemanticTokensLegend # type: boolean # type: boolean | {

    #        /**
    #         * The server supports deltas for full documents.
    #         */
    #        edits?: boolean;
    #    }

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[rangeProvider documentProvider]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.legend = SemanticTokensLegend.new(value['legend']) unless value['legend'].nil?
      self.rangeProvider = value['rangeProvider'] # Unknown type
      self.documentProvider = value['documentProvider'] # Unknown type
      self
    end
  end

  # export interface SemanticTokensRegistrationOptions extends TextDocumentRegistrationOptions, SemanticTokensOptions, StaticRegistrationOptions {
  # }
  class SemanticTokensRegistrationOptions < LSPBase
    attr_accessor :legend, :rangeProvider, :documentProvider # type: SemanticTokensLegend # type: boolean # type: boolean | {

    #        /**
    #         * The server supports deltas for full documents.
    #         */
    #        edits?: boolean;
    #    }

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[rangeProvider documentProvider]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.legend = SemanticTokensLegend.new(value['legend']) unless value['legend'].nil?
      self.rangeProvider = value['rangeProvider'] # Unknown type
      self.documentProvider = value['documentProvider'] # Unknown type
      self
    end
  end

  # export interface SemanticTokensServerCapabilities {
  #     semanticTokensProvider: SemanticTokensOptions | SemanticTokensRegistrationOptions;
  # }
  class SemanticTokensServerCapabilities < LSPBase
    attr_accessor :semanticTokensProvider # type: SemanticTokensOptions | SemanticTokensRegistrationOptions

    def from_h!(value)
      value = {} if value.nil?
      self.semanticTokensProvider = value['semanticTokensProvider'] # Unknown type
      self
    end
  end

  # export interface SemanticTokensParams extends WorkDoneProgressParams, PartialResultParams {
  #     /**
  #      * The text document.
  #      */
  #     textDocument: TextDocumentIdentifier;
  # }
  class SemanticTokensParams < LSPBase
    attr_accessor :textDocument # type: TextDocumentIdentifier

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = value['textDocument'] # Unknown type
      self
    end
  end

  # export interface SemanticTokensEditsParams extends WorkDoneProgressParams, PartialResultParams {
  #     /**
  #      * The text document.
  #      */
  #     textDocument: TextDocumentIdentifier;
  #     /**
  #      * The previous result id.
  #      */
  #     previousResultId: string;
  # }
  class SemanticTokensEditsParams < LSPBase
    attr_accessor :textDocument, :previousResultId # type: TextDocumentIdentifier # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = value['textDocument'] # Unknown type
      self.previousResultId = value['previousResultId']
      self
    end
  end

  # export interface SemanticTokensRangeParams extends WorkDoneProgressParams, PartialResultParams {
  #     /**
  #      * The text document.
  #      */
  #     textDocument: TextDocumentIdentifier;
  #     /**
  #      * The range the semantic tokens are requested for.
  #      */
  #     range: Range;
  # }
  class SemanticTokensRangeParams < LSPBase
    attr_accessor :textDocument, :range # type: TextDocumentIdentifier # type: Range

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = value['textDocument'] # Unknown type
      self.range = value['range'] # Unknown type
      self
    end
  end
end

# rubocop:enable Style/AsciiComments
# rubocop:enable Naming/MethodName
