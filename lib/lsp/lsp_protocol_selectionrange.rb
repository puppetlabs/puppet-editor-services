# frozen_string_literal: true

# DO NOT MODIFY. This file is built automatically
# LSP Protocol: vscode-languageserver-protocol/lib/protocol.selectionRange.d.ts

# rubocop:disable Layout/EmptyLinesAroundClassBody
# rubocop:disable Lint/UselessAssignment
# rubocop:disable Style/AsciiComments
# rubocop:disable Naming/MethodName

module LSP
  # export interface SelectionRangeClientCapabilities {
  #     /**
  #      * Whether implementation supports dynamic registration for selection range providers. If this is set to `true`
  #      * the client supports the new `SelectionRangeRegistrationOptions` return value for the corresponding server
  #      * capability as well.
  #      */
  #     dynamicRegistration?: boolean;
  # }
  class SelectionRangeClientCapabilities < LSPBase
    attr_accessor :dynamicRegistration # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[dynamicRegistration]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.dynamicRegistration = value['dynamicRegistration'] # Unknown type
      self
    end
  end

  # export interface SelectionRangeOptions extends WorkDoneProgressOptions {
  # }
  class SelectionRangeOptions < LSPBase

    def from_h!(value)
      value = {} if value.nil?
      self
    end
  end

  # export interface SelectionRangeRegistrationOptions extends SelectionRangeOptions, TextDocumentRegistrationOptions, StaticRegistrationOptions {
  # }
  class SelectionRangeRegistrationOptions < LSPBase

    def from_h!(value)
      value = {} if value.nil?
      self
    end
  end

  # export interface SelectionRangeParams extends WorkDoneProgressParams, PartialResultParams {
  #     /**
  #      * The text document.
  #      */
  #     textDocument: TextDocumentIdentifier;
  #     /**
  #      * The positions inside the text document.
  #      */
  #     positions: Position[];
  # }
  class SelectionRangeParams < LSPBase
    attr_accessor :textDocument # type: TextDocumentIdentifier
    attr_accessor :positions # type: Position[]

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = value['textDocument'] # Unknown type
      self.positions = value['positions'].map { |val| val } unless value['positions'].nil? # Unknown array type
      self
    end
  end
end

# rubocop:enable Layout/EmptyLinesAroundClassBody
# rubocop:enable Lint/UselessAssignment
# rubocop:enable Style/AsciiComments
# rubocop:enable Naming/MethodName
