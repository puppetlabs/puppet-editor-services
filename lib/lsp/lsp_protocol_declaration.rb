# frozen_string_literal: true

# DO NOT MODIFY. This file is built automatically
# LSP Protocol: vscode-languageserver-protocol/lib/protocol.declaration.d.ts

# rubocop:disable Layout/EmptyLinesAroundClassBody
# rubocop:disable Lint/UselessAssignment
# rubocop:disable Style/AsciiComments

module LSP
  # export interface DeclarationClientCapabilities {
  #     /**
  #      * The text document client capabilities
  #      */
  #     textDocument?: {
  #         /**
  #          * Capabilities specific to the `textDocument/declaration`
  #          */
  #         declaration?: {
  #             /**
  #              * Whether declaration supports dynamic registration. If this is set to `true`
  #              * the client supports the new `(TextDocumentRegistrationOptions & StaticRegistrationOptions)`
  #              * return value for the corresponding server capability as well.
  #              */
  #             dynamicRegistration?: boolean;
  #             /**
  #              * The client supports additional metadata in the form of declaration links.
  #              */
  #             linkSupport?: boolean;
  #         };
  #     };
  # }
  class DeclarationClientCapabilities < LSPBase
    attr_accessor :textDocument # type: {
    #        /**
    #         * Capabilities specific to the `textDocument/declaration`
    #         */
    #        declaration?: {
    #            /**
    #             * Whether declaration supports dynamic registration. If this is set to `true`
    #             * the client supports the new `(TextDocumentRegistrationOptions & StaticRegistrationOptions)`
    #             * return value for the corresponding server capability as well.
    #             */
    #            dynamicRegistration?: boolean;
    #            /**
    #             * The client supports additional metadata in the form of declaration links.
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

  # export interface DeclarationServerCapabilities {
  #     /**
  #      * The server provides Goto Type Definition support.
  #      */
  #     declarationProvider?: boolean | (TextDocumentRegistrationOptions & StaticRegistrationOptions);
  # }
  class DeclarationServerCapabilities < LSPBase
    attr_accessor :declarationProvider # type: boolean | (TextDocumentRegistrationOptions & StaticRegistrationOptions)

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[declarationProvider]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.declarationProvider = value['declarationProvider'] # Unknown type
      self
    end
  end
end

# rubocop:enable Layout/EmptyLinesAroundClassBody
# rubocop:enable Lint/UselessAssignment
# rubocop:enable Style/AsciiComments
