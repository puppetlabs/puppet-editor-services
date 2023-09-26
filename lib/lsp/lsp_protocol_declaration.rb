# frozen_string_literal: true

# DO NOT MODIFY. This file is built automatically
# LSP Protocol: vscode-languageserver-protocol/lib/protocol.declaration.d.ts

# rubocop:disable Layout/EmptyLinesAroundClassBody
# rubocop:disable Lint/UselessAssignment
# rubocop:disable Naming/MethodName

module LSP
  # export interface DeclarationClientCapabilities {
  #     /**
  #      * Whether declaration supports dynamic registration. If this is set to `true`
  #      * the client supports the new `DeclarationRegistrationOptions` return value
  #      * for the corresponding server capability as well.
  #      */
  #     dynamicRegistration?: boolean;
  #     /**
  #      * The client supports additional metadata in the form of declaration links.
  #      */
  #     linkSupport?: boolean;
  # }
  class DeclarationClientCapabilities < LSPBase
    attr_accessor :dynamicRegistration, :linkSupport # type: boolean # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[dynamicRegistration linkSupport]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.dynamicRegistration = value['dynamicRegistration'] # Unknown type
      self.linkSupport = value['linkSupport'] # Unknown type
      self
    end
  end

  # export interface DeclarationOptions extends WorkDoneProgressOptions {
  # }
  class DeclarationOptions < LSPBase

    def from_h!(value)
      value = {} if value.nil?
      self
    end
  end

  # export interface DeclarationRegistrationOptions extends DeclarationOptions, TextDocumentRegistrationOptions, StaticRegistrationOptions {
  # }
  class DeclarationRegistrationOptions < LSPBase

    def from_h!(value)
      value = {} if value.nil?
      self
    end
  end

  # export interface DeclarationParams extends TextDocumentPositionParams, WorkDoneProgressParams, PartialResultParams {
  # }
  class DeclarationParams < LSPBase

    def from_h!(value)
      value = {} if value.nil?
      self
    end
  end
end

# rubocop:enable Layout/EmptyLinesAroundClassBody
# rubocop:enable Lint/UselessAssignment
# rubocop:enable Style/AsciiComments
# rubocop:enable Naming/MethodName
