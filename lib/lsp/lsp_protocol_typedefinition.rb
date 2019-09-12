# frozen_string_literal: true

# DO NOT MODIFY. This file is built automatically
# LSP Protocol: vscode-languageserver-protocol/lib/protocol.typeDefinition.d.ts

# rubocop:disable Layout/EmptyLinesAroundClassBody
# rubocop:disable Lint/UselessAssignment
# rubocop:disable Style/AsciiComments

module LSP
  # export interface TypeDefinitionClientCapabilities {
  #     /**
  #      * The text document client capabilities
  #      */
  #     textDocument?: {
  #         /**
  #          * Capabilities specific to the `textDocument/typeDefinition`
  #          */
  #         typeDefinition?: {
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
  class TypeDefinitionClientCapabilities < LSPBase
    attr_accessor :textDocument # type: {
    #        /**
    #         * Capabilities specific to the `textDocument/typeDefinition`
    #         */
    #        typeDefinition?: {
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

  # export interface TypeDefinitionServerCapabilities {
  #     /**
  #      * The server provides Goto Type Definition support.
  #      */
  #     typeDefinitionProvider?: boolean | (TextDocumentRegistrationOptions & StaticRegistrationOptions);
  # }
  class TypeDefinitionServerCapabilities < LSPBase
    attr_accessor :typeDefinitionProvider # type: boolean | (TextDocumentRegistrationOptions & StaticRegistrationOptions)

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[typeDefinitionProvider]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.typeDefinitionProvider = value['typeDefinitionProvider'] # Unknown type
      self
    end
  end
end

# rubocop:enable Layout/EmptyLinesAroundClassBody
# rubocop:enable Lint/UselessAssignment
# rubocop:enable Style/AsciiComments
