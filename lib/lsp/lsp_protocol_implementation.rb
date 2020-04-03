# frozen_string_literal: true

# DO NOT MODIFY. This file is built automatically
# LSP Protocol: vscode-languageserver-protocol/lib/protocol.implementation.d.ts

# rubocop:disable Layout/EmptyLinesAroundClassBody
# rubocop:disable Lint/UselessAssignment
# rubocop:disable Style/AsciiComments
# rubocop:disable Naming/MethodName

module LSP
  # export interface ImplementationClientCapabilities {
  #     /**
  #      * Whether implementation supports dynamic registration. If this is set to `true`
  #      * the client supports the new `ImplementationRegistrationOptions` return value
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
  class ImplementationClientCapabilities < LSPBase
    attr_accessor :dynamicRegistration # type: boolean
    attr_accessor :linkSupport # type: boolean

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

  # export interface ImplementationOptions extends WorkDoneProgressOptions {
  # }
  class ImplementationOptions < LSPBase

    def from_h!(value)
      value = {} if value.nil?
      self
    end
  end

  # export interface ImplementationRegistrationOptions extends TextDocumentRegistrationOptions, ImplementationOptions, StaticRegistrationOptions {
  # }
  class ImplementationRegistrationOptions < LSPBase

    def from_h!(value)
      value = {} if value.nil?
      self
    end
  end

  # export interface ImplementationParams extends TextDocumentPositionParams, WorkDoneProgressParams, PartialResultParams {
  # }
  class ImplementationParams < LSPBase

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
