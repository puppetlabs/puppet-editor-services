# frozen_string_literal: true

# DO NOT MODIFY. This file is built automatically
# LSP Protocol: vscode-languageserver-protocol/lib/protocol.foldingRange.d.ts

# rubocop:disable Layout/EmptyLinesAroundClassBody
# rubocop:disable Lint/UselessAssignment
# rubocop:disable Style/AsciiComments
# rubocop:disable Naming/MethodName

module LSP
  # export interface FoldingRangeClientCapabilities {
  #     /**
  #      * Whether implementation supports dynamic registration for folding range providers. If this is set to `true`
  #      * the client supports the new `FoldingRangeRegistrationOptions` return value for the corresponding server
  #      * capability as well.
  #      */
  #     dynamicRegistration?: boolean;
  #     /**
  #      * The maximum number of folding ranges that the client prefers to receive per document. The value serves as a
  #      * hint, servers are free to follow the limit.
  #      */
  #     rangeLimit?: number;
  #     /**
  #      * If set, the client signals that it only supports folding complete lines. If set, client will
  #      * ignore specified `startCharacter` and `endCharacter` properties in a FoldingRange.
  #      */
  #     lineFoldingOnly?: boolean;
  # }
  class FoldingRangeClientCapabilities < LSPBase
    attr_accessor :dynamicRegistration, :rangeLimit, :lineFoldingOnly # type: boolean # type: number # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[dynamicRegistration rangeLimit lineFoldingOnly]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.dynamicRegistration = value['dynamicRegistration'] # Unknown type
      self.rangeLimit = value['rangeLimit']
      self.lineFoldingOnly = value['lineFoldingOnly'] # Unknown type
      self
    end
  end

  # export interface FoldingRangeOptions extends WorkDoneProgressOptions {
  # }
  class FoldingRangeOptions < LSPBase

    def from_h!(value)
      value = {} if value.nil?
      self
    end
  end

  # export interface FoldingRangeRegistrationOptions extends TextDocumentRegistrationOptions, FoldingRangeOptions, StaticRegistrationOptions {
  # }
  class FoldingRangeRegistrationOptions < LSPBase

    def from_h!(value)
      value = {} if value.nil?
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
    attr_accessor :startLine, :startCharacter, :endLine, :endCharacter, :kind # type: number # type: number # type: number # type: number # type: string

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

  # export interface FoldingRangeParams extends WorkDoneProgressParams, PartialResultParams {
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
# rubocop:enable Naming/MethodName
