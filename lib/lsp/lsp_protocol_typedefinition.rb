# frozen_string_literal: true

# DO NOT MODIFY. This file is built automatically
# LSP Protocol: vscode-languageserver-protocol/lib/protocol.typeDefinition.d.ts

# rubocop:disable Layout/EmptyLinesAroundClassBody
# rubocop:disable Lint/UselessAssignment
# rubocop:disable Style/AsciiComments
# rubocop:disable Naming/MethodName

module LSP
  # export interface TypeDefinitionClientCapabilities {
  #     /**
  #      * Whether implementation supports dynamic registration. If this is set to `true`
  #      * the client supports the new `TypeDefinitionRegistrationOptions` return value
  #      * for the corresponding server capability as well.
  #      */
  #     dynamicRegistration?: boolean;
  #     /**
  #      * The client supports additional metadata in the form of definition links.
  #      *
  #      * Since 3.14.0
  #      */
  #     linkSupport?: boolean;
  # }
  class TypeDefinitionClientCapabilities < LSPBase
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

  # export interface TypeDefinitionOptions extends WorkDoneProgressOptions {
  # }
  class TypeDefinitionOptions < LSPBase

    def from_h!(value)
      value = {} if value.nil?
      self
    end
  end

  # export interface TypeDefinitionRegistrationOptions extends TextDocumentRegistrationOptions, TypeDefinitionOptions, StaticRegistrationOptions {
  # }
  class TypeDefinitionRegistrationOptions < LSPBase

    def from_h!(value)
      value = {} if value.nil?
      self
    end
  end

  # export interface TypeDefinitionParams extends TextDocumentPositionParams, WorkDoneProgressParams, PartialResultParams {
  # }
  class TypeDefinitionParams < LSPBase

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
