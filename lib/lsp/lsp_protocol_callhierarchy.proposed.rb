# frozen_string_literal: true

# DO NOT MODIFY. This file is built automatically
# LSP Protocol: vscode-languageserver-protocol/lib/protocol.callHierarchy.proposed.d.ts

# rubocop:disable Layout/EmptyLinesAroundClassBody
# rubocop:disable Lint/UselessAssignment
# rubocop:disable Style/AsciiComments
# rubocop:disable Naming/MethodName

module LSP
  # export interface CallHierarchyItem {
  #     /**
  #      * The name of this item.
  #      */
  #     name: string;
  #     /**
  #      * The kind of this item.
  #      */
  #     kind: SymbolKind;
  #     /**
  #      * Tags for this item.
  #      */
  #     tags?: SymbolTag[];
  #     /**
  #      * More detail for this item, e.g. the signature of a function.
  #      */
  #     detail?: string;
  #     /**
  #      * The resource identifier of this item.
  #      */
  #     uri: DocumentUri;
  #     /**
  #      * The range enclosing this symbol not including leading/trailing whitespace but everything else, e.g. comments and code.
  #      */
  #     range: Range;
  #     /**
  #      * The range that should be selected and revealed when this symbol is being picked, e.g. the name of a function.
  #      * Must be contained by the [`range`](#CallHierarchyItem.range).
  #      */
  #     selectionRange: Range;
  # }
  class CallHierarchyItem < LSPBase
    attr_accessor :name, :kind, :tags, :detail, :uri, :range, :selectionRange # type: string # type: SymbolKind # type: SymbolTag[] # type: string # type: DocumentUri # type: Range # type: Range

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[tags detail]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.name = value['name']
      self.kind = value['kind'] # Unknown type
      self.tags = value['tags'].map { |val| val } unless value['tags'].nil? # Unknown array type
      self.detail = value['detail']
      self.uri = value['uri'] # Unknown type
      self.range = value['range'] # Unknown type
      self.selectionRange = value['selectionRange'] # Unknown type
      self
    end
  end

  # export interface CallHierarchyIncomingCall {
  #     /**
  #      * The item that makes the call.
  #      */
  #     from: CallHierarchyItem;
  #     /**
  #      * The range at which at which the calls appears. This is relative to the caller
  #      * denoted by [`this.from`](#CallHierarchyIncomingCall.from).
  #      */
  #     fromRanges: Range[];
  # }
  class CallHierarchyIncomingCall < LSPBase
    attr_accessor :from, :fromRanges # type: CallHierarchyItem # type: Range[]

    def from_h!(value)
      value = {} if value.nil?
      self.from = CallHierarchyItem.new(value['from']) unless value['from'].nil?
      self.fromRanges = value['fromRanges'].map { |val| val } unless value['fromRanges'].nil? # Unknown array type
      self
    end
  end

  # export interface CallHierarchyOutgoingCall {
  #     /**
  #      * The item that is called.
  #      */
  #     to: CallHierarchyItem;
  #     /**
  #      * The range at which this item is called. This is the range relative to the caller, e.g the item
  #      * passed to [`provideCallHierarchyOutgoingCalls`](#CallHierarchyItemProvider.provideCallHierarchyOutgoingCalls)
  #      * and not [`this.to`](#CallHierarchyOutgoingCall.to).
  #      */
  #     fromRanges: Range[];
  # }
  class CallHierarchyOutgoingCall < LSPBase
    attr_accessor :to, :fromRanges # type: CallHierarchyItem # type: Range[]

    def from_h!(value)
      value = {} if value.nil?
      self.to = CallHierarchyItem.new(value['to']) unless value['to'].nil?
      self.fromRanges = value['fromRanges'].map { |val| val } unless value['fromRanges'].nil? # Unknown array type
      self
    end
  end

  # export interface CallHierarchyClientCapabilities {
  #     /**
  #      * The text document client capabilities
  #      */
  #     textDocument?: {
  #         /**
  #          * Capabilities specific to the `textDocument/callHierarchy`.
  #          *
  #          * @since 3.16.0 - Proposed state
  #          */
  #         callHierarchy?: {
  #             /**
  #              * Whether implementation supports dynamic registration. If this is set to `true`
  #              * the client supports the new `(TextDocumentRegistrationOptions & StaticRegistrationOptions)`
  #              * return value for the corresponding server capability as well.
  #              */
  #             dynamicRegistration?: boolean;
  #         };
  #     };
  # }
  class CallHierarchyClientCapabilities < LSPBase
    attr_accessor :textDocument # type: {

    #        /**
    #         * Capabilities specific to the `textDocument/callHierarchy`.
    #         *
    #         * @since 3.16.0 - Proposed state
    #         */
    #        callHierarchy?: {
    #            /**
    #             * Whether implementation supports dynamic registration. If this is set to `true`
    #             * the client supports the new `(TextDocumentRegistrationOptions & StaticRegistrationOptions)`
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

  # export interface CallHierarchyOptions extends WorkDoneProgressOptions {
  # }
  class CallHierarchyOptions < LSPBase

    def from_h!(value)
      value = {} if value.nil?
      self
    end
  end

  # export interface CallHierarchyRegistrationOptions extends TextDocumentRegistrationOptions, CallHierarchyOptions {
  # }
  class CallHierarchyRegistrationOptions < LSPBase

    def from_h!(value)
      value = {} if value.nil?
      self
    end
  end

  # export interface CallHierarchyServerCapabilities {
  #     /**
  #      * The server provides Call Hierarchy support.
  #      */
  #     callHierarchyProvider?: boolean | CallHierarchyOptions | (CallHierarchyRegistrationOptions & StaticRegistrationOptions);
  # }
  class CallHierarchyServerCapabilities < LSPBase
    attr_accessor :callHierarchyProvider # type: boolean | CallHierarchyOptions | (CallHierarchyRegistrationOptions & StaticRegistrationOptions)

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[callHierarchyProvider]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.callHierarchyProvider = value['callHierarchyProvider'] # Unknown type
      self
    end
  end

  # export interface CallHierarchyPrepareParams extends TextDocumentPositionParams, WorkDoneProgressParams {
  # }
  class CallHierarchyPrepareParams < LSPBase

    def from_h!(value)
      value = {} if value.nil?
      self
    end
  end

  # export interface CallHierarchyIncomingCallsParams extends WorkDoneProgressParams, PartialResultParams {
  #     item: CallHierarchyItem;
  # }
  class CallHierarchyIncomingCallsParams < LSPBase
    attr_accessor :item # type: CallHierarchyItem

    def from_h!(value)
      value = {} if value.nil?
      self.item = CallHierarchyItem.new(value['item']) unless value['item'].nil?
      self
    end
  end

  # export interface CallHierarchyOutgoingCallsParams extends WorkDoneProgressParams, PartialResultParams {
  #     item: CallHierarchyItem;
  # }
  class CallHierarchyOutgoingCallsParams < LSPBase
    attr_accessor :item # type: CallHierarchyItem

    def from_h!(value)
      value = {} if value.nil?
      self.item = CallHierarchyItem.new(value['item']) unless value['item'].nil?
      self
    end
  end
end

# rubocop:enable Layout/EmptyLinesAroundClassBody
# rubocop:enable Lint/UselessAssignment
# rubocop:enable Style/AsciiComments
# rubocop:enable Naming/MethodName
