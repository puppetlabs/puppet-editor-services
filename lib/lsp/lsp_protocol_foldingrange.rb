# frozen_string_literal: true

# DO NOT MODIFY. This file is built automatically
# LSP Protocol: vscode-languageserver-protocol/lib/protocol.foldingRange.d.ts

# rubocop:disable Layout/EmptyLinesAroundClassBody
# rubocop:disable Lint/UselessAssignment
# rubocop:disable Style/AsciiComments

module LSP
  # export interface FoldingRangeClientCapabilities {
  #     /**
  #      * The text document client capabilities
  #      */
  #     textDocument?: {
  #         /**
  #          * Capabilities specific to `textDocument/foldingRange` requests
  #          */
  #         foldingRange?: {
  #             /**
  #              * Whether implementation supports dynamic registration for folding range providers. If this is set to `true`
  #              * the client supports the new `(FoldingRangeProviderOptions & TextDocumentRegistrationOptions & StaticRegistrationOptions)`
  #              * return value for the corresponding server capability as well.
  #              */
  #             dynamicRegistration?: boolean;
  #             /**
  #              * The maximum number of folding ranges that the client prefers to receive per document. The value serves as a
  #              * hint, servers are free to follow the limit.
  #              */
  #             rangeLimit?: number;
  #             /**
  #              * If set, the client signals that it only supports folding complete lines. If set, client will
  #              * ignore specified `startCharacter` and `endCharacter` properties in a FoldingRange.
  #              */
  #             lineFoldingOnly?: boolean;
  #         };
  #     };
  # }
  class FoldingRangeClientCapabilities < LSPBase
    attr_accessor :textDocument # type: {
    #        /**
    #         * Capabilities specific to `textDocument/foldingRange` requests
    #         */
    #        foldingRange?: {
    #            /**
    #             * Whether implementation supports dynamic registration for folding range providers. If this is set to `true`
    #             * the client supports the new `(FoldingRangeProviderOptions & TextDocumentRegistrationOptions & StaticRegistrationOptions)`
    #             * return value for the corresponding server capability as well.
    #             */
    #            dynamicRegistration?: boolean;
    #            /**
    #             * The maximum number of folding ranges that the client prefers to receive per document. The value serves as a
    #             * hint, servers are free to follow the limit.
    #             */
    #            rangeLimit?: number;
    #            /**
    #             * If set, the client signals that it only supports folding complete lines. If set, client will
    #             * ignore specified `startCharacter` and `endCharacter` properties in a FoldingRange.
    #             */
    #            lineFoldingOnly?: boolean;
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

  # export interface FoldingRangeProviderOptions {
  # }
  class FoldingRangeProviderOptions < LSPBase

    def from_h!(value)
      value = {} if value.nil?
      self
    end
  end

  # export interface FoldingRangeServerCapabilities {
  #     /**
  #      * The server provides folding provider support.
  #      */
  #     foldingRangeProvider?: boolean | FoldingRangeProviderOptions | (FoldingRangeProviderOptions & TextDocumentRegistrationOptions & StaticRegistrationOptions);
  # }
  class FoldingRangeServerCapabilities < LSPBase
    attr_accessor :foldingRangeProvider # type: boolean | FoldingRangeProviderOptions | (FoldingRangeProviderOptions & TextDocumentRegistrationOptions & StaticRegistrationOptions)

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[foldingRangeProvider]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.foldingRangeProvider = value['foldingRangeProvider'] # Unknown type
      self
    end
  end

  # export interface FoldingRange {
  #     /**
  #      * The zero-based line number from where the folded range starts.
  #      */
  #     startLine: number;
  #     /**
  #      * The zero-based character offset from where the folded range starts. If not defined, defaults to the length of the start line.
  #      */
  #     startCharacter?: number;
  #     /**
  #      * The zero-based line number where the folded range ends.
  #      */
  #     endLine: number;
  #     /**
  #      * The zero-based character offset before the folded range ends. If not defined, defaults to the length of the end line.
  #      */
  #     endCharacter?: number;
  #     /**
  #      * Describes the kind of the folding range such as `comment' or 'region'. The kind
  #      * is used to categorize folding ranges and used by commands like 'Fold all comments'. See
  #      * [FoldingRangeKind](#FoldingRangeKind) for an enumeration of standardized kinds.
  #      */
  #     kind?: string;
  # }
  class FoldingRange < LSPBase
    attr_accessor :startLine # type: number
    attr_accessor :startCharacter # type: number
    attr_accessor :endLine # type: number
    attr_accessor :endCharacter # type: number
    attr_accessor :kind # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[startCharacter endCharacter kind]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.startLine = value['startLine']
      self.startCharacter = value['startCharacter']
      self.endLine = value['endLine']
      self.endCharacter = value['endCharacter']
      self.kind = value['kind']
      self
    end
  end

  # export interface FoldingRangeParams {
  #     /**
  #      * The text document.
  #      */
  #     textDocument: TextDocumentIdentifier;
  # }
  class FoldingRangeParams < LSPBase
    attr_accessor :textDocument # type: TextDocumentIdentifier

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = value['textDocument'] # Unknown type
      self
    end
  end
end

# rubocop:enable Layout/EmptyLinesAroundClassBody
# rubocop:enable Lint/UselessAssignment
# rubocop:enable Style/AsciiComments
