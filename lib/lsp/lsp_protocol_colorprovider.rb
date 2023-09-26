# frozen_string_literal: true

# DO NOT MODIFY. This file is built automatically
# LSP Protocol: vscode-languageserver-protocol/lib/protocol.colorProvider.d.ts

# rubocop:disable Layout/EmptyLinesAroundClassBody
# rubocop:disable Lint/UselessAssignment
# rubocop:disable Naming/MethodName

module LSP
  # export interface DocumentColorClientCapabilities {
  #     /**
  #      * Whether implementation supports dynamic registration. If this is set to `true`
  #      * the client supports the new `DocumentColorRegistrationOptions` return value
  #      * for the corresponding server capability as well.
  #      */
  #     dynamicRegistration?: boolean;
  # }
  class DocumentColorClientCapabilities < LSPBase
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

  # export interface DocumentColorOptions extends WorkDoneProgressOptions {
  # }
  class DocumentColorOptions < LSPBase

    def from_h!(value)
      value = {} if value.nil?
      self
    end
  end

  # export interface DocumentColorRegistrationOptions extends TextDocumentRegistrationOptions, StaticRegistrationOptions, DocumentColorOptions {
  # }
  class DocumentColorRegistrationOptions < LSPBase

    def from_h!(value)
      value = {} if value.nil?
      self
    end
  end

  # export interface DocumentColorParams extends WorkDoneProgressParams, PartialResultParams {
  #     /**
  #      * The text document.
  #      */
  #     textDocument: TextDocumentIdentifier;
  # }
  class DocumentColorParams < LSPBase
    attr_accessor :textDocument # type: TextDocumentIdentifier

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = value['textDocument'] # Unknown type
      self
    end
  end

  # export interface ColorPresentationParams extends WorkDoneProgressParams, PartialResultParams {
  #     /**
  #      * The text document.
  #      */
  #     textDocument: TextDocumentIdentifier;
  #     /**
  #      * The color to request presentations for.
  #      */
  #     color: Color;
  #     /**
  #      * The range where the color would be inserted. Serves as a context.
  #      */
  #     range: Range;
  # }
  class ColorPresentationParams < LSPBase
    attr_accessor :textDocument, :color, :range # type: TextDocumentIdentifier # type: Color # type: Range

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = value['textDocument'] # Unknown type
      self.color = value['color'] # Unknown type
      self.range = value['range'] # Unknown type
      self
    end
  end
end

# rubocop:enable Layout/EmptyLinesAroundClassBody
# rubocop:enable Lint/UselessAssignment
# rubocop:enable Style/AsciiComments
# rubocop:enable Naming/MethodName
