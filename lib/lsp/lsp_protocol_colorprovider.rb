# frozen_string_literal: true

# DO NOT MODIFY. This file is built automatically
# LSP Protocol: vscode-languageserver-protocol/lib/protocol.colorProvider.d.ts

# rubocop:disable Layout/EmptyLinesAroundClassBody
# rubocop:disable Lint/UselessAssignment
# rubocop:disable Style/AsciiComments

module LSP
  # export interface ColorClientCapabilities {
  #     /**
  #      * The text document client capabilities
  #      */
  #     textDocument?: {
  #         /**
  #          * Capabilities specific to the colorProvider
  #          */
  #         colorProvider?: {
  #             /**
  #              * Whether implementation supports dynamic registration. If this is set to `true`
  #              * the client supports the new `(ColorProviderOptions & TextDocumentRegistrationOptions & StaticRegistrationOptions)`
  #              * return value for the corresponding server capability as well.
  #              */
  #             dynamicRegistration?: boolean;
  #         };
  #     };
  # }
  class ColorClientCapabilities < LSPBase
    attr_accessor :textDocument # type: {
    #        /**
    #         * Capabilities specific to the colorProvider
    #         */
    #        colorProvider?: {
    #            /**
    #             * Whether implementation supports dynamic registration. If this is set to `true`
    #             * the client supports the new `(ColorProviderOptions & TextDocumentRegistrationOptions & StaticRegistrationOptions)`
    #             * return value for the corresponding server capability as well.
    #             */
    #            dynamicRegistration?: boolean;
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

  # export interface ColorProviderOptions {
  # }
  class ColorProviderOptions < LSPBase

    def from_h!(value)
      value = {} if value.nil?
      self
    end
  end

  # export interface ColorServerCapabilities {
  #     /**
  #      * The server provides color provider support.
  #      */
  #     colorProvider?: boolean | ColorProviderOptions | (ColorProviderOptions & TextDocumentRegistrationOptions & StaticRegistrationOptions);
  # }
  class ColorServerCapabilities < LSPBase
    attr_accessor :colorProvider # type: boolean | ColorProviderOptions | (ColorProviderOptions & TextDocumentRegistrationOptions & StaticRegistrationOptions)

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[colorProvider]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.colorProvider = value['colorProvider'] # Unknown type
      self
    end
  end

  # export interface DocumentColorParams {
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

  # export interface ColorPresentationParams {
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
    attr_accessor :textDocument # type: TextDocumentIdentifier
    attr_accessor :color # type: Color
    attr_accessor :range # type: Range

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
