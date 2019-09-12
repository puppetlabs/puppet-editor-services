# frozen_string_literal: true

# DO NOT MODIFY. This file is built automatically
# LSP Protocol: vscode-languageserver-protocol/lib/protocol.implementation.d.ts

# rubocop:disable Layout/EmptyLinesAroundClassBody
# rubocop:disable Lint/UselessAssignment
# rubocop:disable Style/AsciiComments

module LSP
  # export interface ImplementationClientCapabilities {
  #     /**
  #      * The text document client capabilities
  #      */
  #     textDocument?: {
  #         /**
  #          * Capabilities specific to the `textDocument/implementation`
  #          */
  #         implementation?: {
  #             /**
  #              * Whether implementation supports dynamic registration. If this is set to `true`
  #              * the client supports the new `(TextDocumentRegistrationOptions & StaticRegistrationOptions)`
  #              * return value for the corresponding server capability as well.
  #              */
  #             dynamicRegistration?: boolean;
  #             /**
  #              * The client supports additional metadata in the form of definition links.
  #              */
  #             linkSupport?: boolean;
  #         };
  #     };
  # }
  class ImplementationClientCapabilities < LSPBase
    attr_accessor :textDocument # type: {
    #        /**
    #         * Capabilities specific to the `textDocument/implementation`
    #         */
    #        implementation?: {
    #            /**
    #             * Whether implementation supports dynamic registration. If this is set to `true`
    #             * the client supports the new `(TextDocumentRegistrationOptions & StaticRegistrationOptions)`
    #             * return value for the corresponding server capability as well.
    #             */
    #            dynamicRegistration?: boolean;
    #            /**
    #             * The client supports additional metadata in the form of definition links.
    #             */
    #            linkSupport?: boolean;
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

  # export interface ImplementationServerCapabilities {
  #     /**
  #      * The server provides Goto Implementation support.
  #      */
  #     implementationProvider?: boolean | (TextDocumentRegistrationOptions & StaticRegistrationOptions);
  # }
  class ImplementationServerCapabilities < LSPBase
    attr_accessor :implementationProvider # type: boolean | (TextDocumentRegistrationOptions & StaticRegistrationOptions)

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[implementationProvider]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.implementationProvider = value['implementationProvider'] # Unknown type
      self
    end
  end
end

# rubocop:enable Layout/EmptyLinesAroundClassBody
# rubocop:enable Lint/UselessAssignment
# rubocop:enable Style/AsciiComments
