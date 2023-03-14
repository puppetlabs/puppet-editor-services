# frozen_string_literal: true

# DO NOT MODIFY. This file is built automatically
# LSP Protocol: vscode-languageserver-protocol/lib/protocol.d.ts

# rubocop:disable Layout/EmptyLinesAroundClassBody
# rubocop:disable Lint/UselessAssignment
# rubocop:disable Style/AsciiComments
# rubocop:disable Naming/MethodName

module LSP
  # export interface Registration {
  #     /**
  #      * The id used to register the request. The id can be used to deregister
  #      * the request again.
  #      */
  #     id: string;
  #     /**
  #      * The method to register for.
  #      */
  #     method: string;
  #     /**
  #      * Options necessary for the registration.
  #      */
  #     registerOptions?: any;
  # }
  class Registration < LSPBase
    attr_accessor :id, :method__lsp, :registerOptions # type: string # type: string # type: any

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[registerOptions]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.id = value['id']
      self.method__lsp = value['method']
      self.registerOptions = value['registerOptions']
      self
    end
  end

  # export interface RegistrationParams {
  #     registrations: Registration[];
  # }
  class RegistrationParams < LSPBase
    attr_accessor :registrations # type: Registration[]

    def from_h!(value)
      value = {} if value.nil?
      self.registrations = to_typed_aray(value['registrations'], Registration)
      self
    end
  end

  # export interface Unregistration {
  #     /**
  #      * The id used to unregister the request or notification. Usually an id
  #      * provided during the register request.
  #      */
  #     id: string;
  #     /**
  #      * The method to unregister for.
  #      */
  #     method: string;
  # }
  class Unregistration < LSPBase
    attr_accessor :id, :method__lsp # type: string # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.id = value['id']
      self.method__lsp = value['method']
      self
    end
  end

  # export interface UnregistrationParams {
  #     unregisterations: Unregistration[];
  # }
  class UnregistrationParams < LSPBase
    attr_accessor :unregisterations # type: Unregistration[]

    def from_h!(value)
      value = {} if value.nil?
      self.unregisterations = to_typed_aray(value['unregisterations'], Unregistration)
      self
    end
  end

  # export interface WorkDoneProgressParams {
  #     /**
  #      * An optional token that a server can use to report work done progress.
  #      */
  #     workDoneToken?: ProgressToken;
  # }
  class WorkDoneProgressParams < LSPBase
    attr_accessor :workDoneToken # type: ProgressToken

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[workDoneToken]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.workDoneToken = value['workDoneToken'] # Unknown type
      self
    end
  end

  # export interface PartialResultParams {
  #     /**
  #      * An optional token that a server can use to report partial results (e.g. streaming) to
  #      * the client.
  #      */
  #     partialResultToken?: ProgressToken;
  # }
  class PartialResultParams < LSPBase
    attr_accessor :partialResultToken # type: ProgressToken

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[partialResultToken]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.partialResultToken = value['partialResultToken'] # Unknown type
      self
    end
  end

  # export interface TextDocumentPositionParams {
  #     /**
  #      * The text document.
  #      */
  #     textDocument: TextDocumentIdentifier;
  #     /**
  #      * The position inside the text document.
  #      */
  #     position: Position;
  # }
  class TextDocumentPositionParams < LSPBase
    attr_accessor :textDocument, :position # type: TextDocumentIdentifier # type: Position

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = value['textDocument'] # Unknown type
      self.position = value['position'] # Unknown type
      self
    end
  end

  # export interface StaticRegistrationOptions {
  #     /**
  #      * The id used to register the request. The id can be used to deregister
  #      * the request again. See also Registration#id.
  #      */
  #     id?: string;
  # }
  class StaticRegistrationOptions < LSPBase
    attr_accessor :id # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[id]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.id = value['id']
      self
    end
  end

  # export interface TextDocumentRegistrationOptions {
  #     /**
  #      * A document selector to identify the scope of the registration. If set to null
  #      * the document selector provided on the client side will be used.
  #      */
  #     documentSelector: DocumentSelector | null;
  # }
  class TextDocumentRegistrationOptions < LSPBase
    attr_accessor :documentSelector # type: DocumentSelector | null

    def from_h!(value)
      value = {} if value.nil?
      self.documentSelector = value['documentSelector'] # Unknown type
      self
    end
  end

  # export interface SaveOptions {
  #     /**
  #      * The client is supposed to include the content on save.
  #      */
  #     includeText?: boolean;
  # }
  class SaveOptions < LSPBase
    attr_accessor :includeText # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[includeText]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.includeText = value['includeText'] # Unknown type
      self
    end
  end

  # export interface WorkDoneProgressOptions {
  #     workDoneProgress?: boolean;
  # }
  class WorkDoneProgressOptions < LSPBase
    attr_accessor :workDoneProgress # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[workDoneProgress]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.workDoneProgress = value['workDoneProgress'] # Unknown type
      self
    end
  end

  # export interface InitializeResult<T = any> {
  #     /**
  #      * The capabilities the language server provides.
  #      */
  #     capabilities: ServerCapabilities<T>;
  #     /**
  #      * Information about the server.
  #      *
  #      * @since 3.15.0
  #      */
  #     serverInfo?: {
  #         /**
  #          * The name of the server as defined by the server.
  #          */
  #         name: string;
  #         /**
  #          * The servers's version as defined by the server.
  #          */
  #         version?: string;
  #     };
  #     /**
  #      * Custom initialization results.
  #      */
  #     [custom: string]: any;
  # }
  class InitializeResult < LSPBase
    attr_accessor :capabilities, :serverInfo # type: ServerCapabilities<T> # type: {

    #        /**
    #         * The name of the server as defined by the server.
    #         */
    #        name: string;
    #        /**
    #         * The servers's version as defined by the server.
    #         */
    #        version?: string;
    #    }

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[serverInfo]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.capabilities = value['capabilities'] # Unknown type
      self.serverInfo = value['serverInfo'] # Unknown type
      self
    end
  end

  # export interface InitializeError {
  #     /**
  #      * Indicates whether the client execute the following retry logic:
  #      * (1) show the message provided by the ResponseError to the user
  #      * (2) user selects retry or cancel
  #      * (3) if user selected retry the initialize method is sent again.
  #      */
  #     retry: boolean;
  # }
  class InitializeError < LSPBase
    attr_accessor :retry # type: boolean

    def from_h!(value)
      value = {} if value.nil?
      self.retry = value['retry'] # Unknown type
      self
    end
  end

  # export interface InitializedParams {
  # }
  class InitializedParams < LSPBase

    def from_h!(value)
      value = {} if value.nil?
      self
    end
  end

  # export interface DidChangeConfigurationClientCapabilities {
  #     /**
  #      * Did change configuration notification supports dynamic registration.
  #      */
  #     dynamicRegistration?: boolean;
  # }
  class DidChangeConfigurationClientCapabilities < LSPBase
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

  # export interface DidChangeConfigurationRegistrationOptions {
  #     section?: string | string[];
  # }
  class DidChangeConfigurationRegistrationOptions < LSPBase
    attr_accessor :section # type: string | string[]

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[section]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.section = value['section'] # Unknown type
      self
    end
  end

  # export interface DidChangeConfigurationParams {
  #     /**
  #      * The actual changed settings
  #      */
  #     settings: any;
  # }
  class DidChangeConfigurationParams < LSPBase
    attr_accessor :settings # type: any

    def from_h!(value)
      value = {} if value.nil?
      self.settings = value['settings']
      self
    end
  end

  # export interface ShowMessageParams {
  #     /**
  #      * The message type. See {@link MessageType}
  #      */
  #     type: MessageType;
  #     /**
  #      * The actual message
  #      */
  #     message: string;
  # }
  class ShowMessageParams < LSPBase
    attr_accessor :type, :message # type: MessageType # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.type = value['type'] # Unknown type
      self.message = value['message']
      self
    end
  end

  # export interface MessageActionItem {
  #     /**
  #      * A short title like 'Retry', 'Open Log' etc.
  #      */
  #     title: string;
  # }
  class MessageActionItem < LSPBase
    attr_accessor :title # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.title = value['title']
      self
    end
  end

  # export interface ShowMessageRequestParams {
  #     /**
  #      * The message type. See {@link MessageType}
  #      */
  #     type: MessageType;
  #     /**
  #      * The actual message
  #      */
  #     message: string;
  #     /**
  #      * The message action items to present.
  #      */
  #     actions?: MessageActionItem[];
  # }
  class ShowMessageRequestParams < LSPBase
    attr_accessor :type, :message, :actions # type: MessageType # type: string # type: MessageActionItem[]

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[actions]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.type = value['type'] # Unknown type
      self.message = value['message']
      self.actions = to_typed_aray(value['actions'], MessageActionItem)
      self
    end
  end

  # export interface LogMessageParams {
  #     /**
  #      * The message type. See {@link MessageType}
  #      */
  #     type: MessageType;
  #     /**
  #      * The actual message
  #      */
  #     message: string;
  # }
  class LogMessageParams < LSPBase
    attr_accessor :type, :message # type: MessageType # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.type = value['type'] # Unknown type
      self.message = value['message']
      self
    end
  end

  # export interface TextDocumentSyncClientCapabilities {
  #     /**
  #      * Whether text document synchronization supports dynamic registration.
  #      */
  #     dynamicRegistration?: boolean;
  #     /**
  #      * The client supports sending will save notifications.
  #      */
  #     willSave?: boolean;
  #     /**
  #      * The client supports sending a will save request and
  #      * waits for a response providing text edits which will
  #      * be applied to the document before it is saved.
  #      */
  #     willSaveWaitUntil?: boolean;
  #     /**
  #      * The client supports did save notifications.
  #      */
  #     didSave?: boolean;
  # }
  class TextDocumentSyncClientCapabilities < LSPBase
    attr_accessor :dynamicRegistration, :willSave, :willSaveWaitUntil, :didSave # type: boolean # type: boolean # type: boolean # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[dynamicRegistration willSave willSaveWaitUntil didSave]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.dynamicRegistration = value['dynamicRegistration'] # Unknown type
      self.willSave = value['willSave'] # Unknown type
      self.willSaveWaitUntil = value['willSaveWaitUntil'] # Unknown type
      self.didSave = value['didSave'] # Unknown type
      self
    end
  end

  # export interface TextDocumentSyncOptions {
  #     /**
  #      * Open and close notifications are sent to the server. If omitted open close notification should not
  #      * be sent.
  #      */
  #     openClose?: boolean;
  #     /**
  #      * Change notifications are sent to the server. See TextDocumentSyncKind.None, TextDocumentSyncKind.Full
  #      * and TextDocumentSyncKind.Incremental. If omitted it defaults to TextDocumentSyncKind.None.
  #      */
  #     change?: TextDocumentSyncKind;
  #     /**
  #      * If present will save notifications are sent to the server. If omitted the notification should not be
  #      * sent.
  #      */
  #     willSave?: boolean;
  #     /**
  #      * If present will save wait until requests are sent to the server. If omitted the request should not be
  #      * sent.
  #      */
  #     willSaveWaitUntil?: boolean;
  #     /**
  #      * If present save notifications are sent to the server. If omitted the notification should not be
  #      * sent.
  #      */
  #     save?: SaveOptions;
  # }
  class TextDocumentSyncOptions < LSPBase
    attr_accessor :openClose, :change, :willSave, :willSaveWaitUntil, :save # type: boolean # type: TextDocumentSyncKind # type: boolean # type: boolean # type: SaveOptions

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[openClose change willSave willSaveWaitUntil save]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.openClose = value['openClose'] # Unknown type
      self.change = value['change'] # Unknown type
      self.willSave = value['willSave'] # Unknown type
      self.willSaveWaitUntil = value['willSaveWaitUntil'] # Unknown type
      self.save = SaveOptions.new(value['save']) unless value['save'].nil?
      self
    end
  end

  # export interface DidOpenTextDocumentParams {
  #     /**
  #      * The document that was opened.
  #      */
  #     textDocument: TextDocumentItem;
  # }
  class DidOpenTextDocumentParams < LSPBase
    attr_accessor :textDocument # type: TextDocumentItem

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = value['textDocument'] # Unknown type
      self
    end
  end

  # export interface DidChangeTextDocumentParams {
  #     /**
  #      * The document that did change. The version number points
  #      * to the version after all provided content changes have
  #      * been applied.
  #      */
  #     textDocument: VersionedTextDocumentIdentifier;
  #     /**
  #      * The actual content changes. The content changes describe single state changes
  #      * to the document. So if there are two content changes c1 (at array index 0) and
  #      * c2 (at array index 1) for a document in state S then c1 moves the document from
  #      * S to S' and c2 from S' to S''. So c1 is computed on the state S and c2 is computed
  #      * on the state S'.
  #      *
  #      * To mirror the content of a document using change events use the following approach:
  #      * - start with the same initial content
  #      * - apply the 'textDocument/didChange' notifications in the order you recevie them.
  #      * - apply the `TextDocumentContentChangeEvent`s in a single notification in the order
  #      *   you receive them.
  #      */
  #     contentChanges: TextDocumentContentChangeEvent[];
  # }
  class DidChangeTextDocumentParams < LSPBase
    attr_accessor :textDocument, :contentChanges # type: VersionedTextDocumentIdentifier # type: TextDocumentContentChangeEvent[]

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = value['textDocument'] # Unknown type
      self.contentChanges = value['contentChanges'].map { |val| val } unless value['contentChanges'].nil? # Unknown array type
      self
    end
  end

  # export interface TextDocumentChangeRegistrationOptions extends TextDocumentRegistrationOptions {
  #     /**
  #      * How documents are synced to the server.
  #      */
  #     syncKind: TextDocumentSyncKind;
  # }
  class TextDocumentChangeRegistrationOptions < LSPBase
    attr_accessor :syncKind, :documentSelector # type: TextDocumentSyncKind # type: DocumentSelector | null

    def from_h!(value)
      value = {} if value.nil?
      self.syncKind = value['syncKind'] # Unknown type
      self.documentSelector = value['documentSelector'] # Unknown type
      self
    end
  end

  # export interface DidCloseTextDocumentParams {
  #     /**
  #      * The document that was closed.
  #      */
  #     textDocument: TextDocumentIdentifier;
  # }
  class DidCloseTextDocumentParams < LSPBase
    attr_accessor :textDocument # type: TextDocumentIdentifier

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = value['textDocument'] # Unknown type
      self
    end
  end

  # export interface DidSaveTextDocumentParams {
  #     /**
  #      * The document that was closed.
  #      */
  #     textDocument: VersionedTextDocumentIdentifier;
  #     /**
  #      * Optional the content when saved. Depends on the includeText value
  #      * when the save notification was requested.
  #      */
  #     text?: string;
  # }
  class DidSaveTextDocumentParams < LSPBase
    attr_accessor :textDocument, :text # type: VersionedTextDocumentIdentifier # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[text]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = value['textDocument'] # Unknown type
      self.text = value['text']
      self
    end
  end

  # export interface TextDocumentSaveRegistrationOptions extends TextDocumentRegistrationOptions, SaveOptions {
  # }
  class TextDocumentSaveRegistrationOptions < LSPBase
    attr_accessor :documentSelector, :includeText # type: DocumentSelector | null # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[includeText]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.documentSelector = value['documentSelector'] # Unknown type
      self.includeText = value['includeText'] # Unknown type
      self
    end
  end

  # export interface WillSaveTextDocumentParams {
  #     /**
  #      * The document that will be saved.
  #      */
  #     textDocument: TextDocumentIdentifier;
  #     /**
  #      * The 'TextDocumentSaveReason'.
  #      */
  #     reason: TextDocumentSaveReason;
  # }
  class WillSaveTextDocumentParams < LSPBase
    attr_accessor :textDocument, :reason # type: TextDocumentIdentifier # type: TextDocumentSaveReason

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = value['textDocument'] # Unknown type
      self.reason = value['reason'] # Unknown type
      self
    end
  end

  # export interface DidChangeWatchedFilesClientCapabilities {
  #     /**
  #      * Did change watched files notification supports dynamic registration. Please note
  #      * that the current protocol doesn't support static configuration for file changes
  #      * from the server side.
  #      */
  #     dynamicRegistration?: boolean;
  # }
  class DidChangeWatchedFilesClientCapabilities < LSPBase
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

  # export interface DidChangeWatchedFilesParams {
  #     /**
  #      * The actual file events.
  #      */
  #     changes: FileEvent[];
  # }
  class DidChangeWatchedFilesParams < LSPBase
    attr_accessor :changes # type: FileEvent[]

    def from_h!(value)
      value = {} if value.nil?
      self.changes = to_typed_aray(value['changes'], FileEvent)
      self
    end
  end

  # export interface FileEvent {
  #     /**
  #      * The file's uri.
  #      */
  #     uri: DocumentUri;
  #     /**
  #      * The change type.
  #      */
  #     type: FileChangeType;
  # }
  class FileEvent < LSPBase
    attr_accessor :uri, :type # type: DocumentUri # type: FileChangeType

    def from_h!(value)
      value = {} if value.nil?
      self.uri = value['uri'] # Unknown type
      self.type = value['type'] # Unknown type
      self
    end
  end

  # export interface DidChangeWatchedFilesRegistrationOptions {
  #     /**
  #      * The watchers to register.
  #      */
  #     watchers: FileSystemWatcher[];
  # }
  class DidChangeWatchedFilesRegistrationOptions < LSPBase
    attr_accessor :watchers # type: FileSystemWatcher[]

    def from_h!(value)
      value = {} if value.nil?
      self.watchers = to_typed_aray(value['watchers'], FileSystemWatcher)
      self
    end
  end

  # export interface FileSystemWatcher {
  #     /**
  #      * The  glob pattern to watch. Glob patterns can have the following syntax:
  #      * - `*` to match one or more characters in a path segment
  #      * - `?` to match on one character in a path segment
  #      * - `**` to match any number of path segments, including none
  #      * - `{}` to group conditions (e.g. `**​/*.{ts,js}` matches all TypeScript and JavaScript files)
  #      * - `[]` to declare a range of characters to match in a path segment (e.g., `example.[0-9]` to match on `example.0`, `example.1`, …)
  #      * - `[!...]` to negate a range of characters to match in a path segment (e.g., `example.[!0-9]` to match on `example.a`, `example.b`, but not `example.0`)
  #      */
  #     globPattern: string;
  #     /**
  #      * The kind of events of interest. If omitted it defaults
  #      * to WatchKind.Create | WatchKind.Change | WatchKind.Delete
  #      * which is 7.
  #      */
  #     kind?: number;
  # }
  class FileSystemWatcher < LSPBase
    attr_accessor :globPattern, :kind # type: string # type: number

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[kind]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.globPattern = value['globPattern']
      self.kind = value['kind']
      self
    end
  end

  # export interface PublishDiagnosticsClientCapabilities {
  #     /**
  #      * Whether the clients accepts diagnostics with related information.
  #      */
  #     relatedInformation?: boolean;
  #     /**
  #      * Client supports the tag property to provide meta data about a diagnostic.
  #      * Clients supporting tags have to handle unknown tags gracefully.
  #      *
  #      * @since 3.15.0
  #      */
  #     tagSupport?: {
  #         /**
  #          * The tags supported by the client.
  #          */
  #         valueSet: DiagnosticTag[];
  #     };
  #     /**
  #      * Whether the client interprets the version property of the
  #      * `textDocument/publishDiagnostics` notification`s parameter.
  #      *
  #      * @since 3.15.0
  #      */
  #     versionSupport?: boolean;
  # }
  class PublishDiagnosticsClientCapabilities < LSPBase
    attr_accessor :relatedInformation, :tagSupport # type: boolean # type: {
    #        /**
    #         * The tags supported by the client.
    #         */
    #        valueSet: DiagnosticTag[];
    #    }
    attr_accessor :versionSupport # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[relatedInformation tagSupport versionSupport]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.relatedInformation = value['relatedInformation'] # Unknown type
      self.tagSupport = value['tagSupport'] # Unknown type
      self.versionSupport = value['versionSupport'] # Unknown type
      self
    end
  end

  # export interface PublishDiagnosticsParams {
  #     /**
  #      * The URI for which diagnostic information is reported.
  #      */
  #     uri: DocumentUri;
  #     /**
  #      * Optional the version number of the document the diagnostics are published for.
  #      *
  #      * @since 3.15.0
  #      */
  #     version?: number;
  #     /**
  #      * An array of diagnostic information items.
  #      */
  #     diagnostics: Diagnostic[];
  # }
  class PublishDiagnosticsParams < LSPBase
    attr_accessor :uri, :version, :diagnostics # type: DocumentUri # type: number # type: Diagnostic[]

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[version]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.uri = value['uri'] # Unknown type
      self.version = value['version']
      self.diagnostics = value['diagnostics'].map { |val| val } unless value['diagnostics'].nil? # Unknown array type
      self
    end
  end

  # export interface CompletionClientCapabilities {
  #     /**
  #      * Whether completion supports dynamic registration.
  #      */
  #     dynamicRegistration?: boolean;
  #     /**
  #      * The client supports the following `CompletionItem` specific
  #      * capabilities.
  #      */
  #     completionItem?: {
  #         /**
  #          * Client supports snippets as insert text.
  #          *
  #          * A snippet can define tab stops and placeholders with `$1`, `$2`
  #          * and `${3:foo}`. `$0` defines the final tab stop, it defaults to
  #          * the end of the snippet. Placeholders with equal identifiers are linked,
  #          * that is typing in one will update others too.
  #          */
  #         snippetSupport?: boolean;
  #         /**
  #          * Client supports commit characters on a completion item.
  #          */
  #         commitCharactersSupport?: boolean;
  #         /**
  #          * Client supports the follow content formats for the documentation
  #          * property. The order describes the preferred format of the client.
  #          */
  #         documentationFormat?: MarkupKind[];
  #         /**
  #          * Client supports the deprecated property on a completion item.
  #          */
  #         deprecatedSupport?: boolean;
  #         /**
  #          * Client supports the preselect property on a completion item.
  #          */
  #         preselectSupport?: boolean;
  #         /**
  #          * Client supports the tag property on a completion item. Clients supporting
  #          * tags have to handle unknown tags gracefully. Clients especially need to
  #          * preserve unknown tags when sending a completion item back to the server in
  #          * a resolve call.
  #          *
  #          * @since 3.15.0
  #          */
  #         tagSupport?: {
  #             /**
  #              * The tags supported by the client.
  #              */
  #             valueSet: CompletionItemTag[];
  #         };
  #     };
  #     completionItemKind?: {
  #         /**
  #          * The completion item kind values the client supports. When this
  #          * property exists the client also guarantees that it will
  #          * handle values outside its set gracefully and falls back
  #          * to a default value when unknown.
  #          *
  #          * If this property is not present the client only supports
  #          * the completion items kinds from `Text` to `Reference` as defined in
  #          * the initial version of the protocol.
  #          */
  #         valueSet?: CompletionItemKind[];
  #     };
  #     /**
  #      * The client supports to send additional context information for a
  #      * `textDocument/completion` requestion.
  #      */
  #     contextSupport?: boolean;
  # }
  class CompletionClientCapabilities < LSPBase
    attr_accessor :dynamicRegistration, :completionItem # type: boolean # type: {
    #        /**
    #         * Client supports snippets as insert text.
    #         *
    #         * A snippet can define tab stops and placeholders with `$1`, `$2`
    #         * and `${3:foo}`. `$0` defines the final tab stop, it defaults to
    #         * the end of the snippet. Placeholders with equal identifiers are linked,
    #         * that is typing in one will update others too.
    #         */
    #        snippetSupport?: boolean;
    #        /**
    #         * Client supports commit characters on a completion item.
    #         */
    #        commitCharactersSupport?: boolean;
    #        /**
    #         * Client supports the follow content formats for the documentation
    #         * property. The order describes the preferred format of the client.
    #         */
    #        documentationFormat?: MarkupKind[];
    #        /**
    #         * Client supports the deprecated property on a completion item.
    #         */
    #        deprecatedSupport?: boolean;
    #        /**
    #         * Client supports the preselect property on a completion item.
    #         */
    #        preselectSupport?: boolean;
    #        /**
    #         * Client supports the tag property on a completion item. Clients supporting
    #         * tags have to handle unknown tags gracefully. Clients especially need to
    #         * preserve unknown tags when sending a completion item back to the server in
    #         * a resolve call.
    #         *
    #         * @since 3.15.0
    #         */
    #        tagSupport?: {
    #            /**
    #             * The tags supported by the client.
    #             */
    #            valueSet: CompletionItemTag[];
    #        };
    #    }
    attr_accessor :completionItemKind # type: {
    #        /**
    #         * The completion item kind values the client supports. When this
    #         * property exists the client also guarantees that it will
    #         * handle values outside its set gracefully and falls back
    #         * to a default value when unknown.
    #         *
    #         * If this property is not present the client only supports
    #         * the completion items kinds from `Text` to `Reference` as defined in
    #         * the initial version of the protocol.
    #         */
    #        valueSet?: CompletionItemKind[];
    #    }
    attr_accessor :contextSupport # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[dynamicRegistration completionItem completionItemKind contextSupport]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.dynamicRegistration = value['dynamicRegistration'] # Unknown type
      self.completionItem = value['completionItem'] # Unknown type
      self.completionItemKind = value['completionItemKind'] # Unknown type
      self.contextSupport = value['contextSupport'] # Unknown type
      self
    end
  end

  # export interface CompletionContext {
  #     /**
  #      * How the completion was triggered.
  #      */
  #     triggerKind: CompletionTriggerKind;
  #     /**
  #      * The trigger character (a single character) that has trigger code complete.
  #      * Is undefined if `triggerKind !== CompletionTriggerKind.TriggerCharacter`
  #      */
  #     triggerCharacter?: string;
  # }
  class CompletionContext < LSPBase
    attr_accessor :triggerKind, :triggerCharacter # type: CompletionTriggerKind # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[triggerCharacter]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.triggerKind = value['triggerKind'] # Unknown type
      self.triggerCharacter = value['triggerCharacter']
      self
    end
  end

  # export interface CompletionParams extends TextDocumentPositionParams, WorkDoneProgressParams, PartialResultParams {
  #     /**
  #      * The completion context. This is only available it the client specifies
  #      * to send this using the client capability `textDocument.completion.contextSupport === true`
  #      */
  #     context?: CompletionContext;
  # }
  class CompletionParams < LSPBase
    attr_accessor :context, :textDocument, :position, :workDoneToken, :partialResultToken # type: CompletionContext # type: TextDocumentIdentifier # type: Position # type: ProgressToken # type: ProgressToken

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[context workDoneToken partialResultToken]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.context = CompletionContext.new(value['context']) unless value['context'].nil?
      self.textDocument = value['textDocument'] # Unknown type
      self.position = value['position'] # Unknown type
      self.workDoneToken = value['workDoneToken'] # Unknown type
      self.partialResultToken = value['partialResultToken'] # Unknown type
      self
    end
  end

  # export interface CompletionOptions extends WorkDoneProgressOptions {
  #     /**
  #      * Most tools trigger completion request automatically without explicitly requesting
  #      * it using a keyboard shortcut (e.g. Ctrl+Space). Typically they do so when the user
  #      * starts to type an identifier. For example if the user types `c` in a JavaScript file
  #      * code complete will automatically pop up present `console` besides others as a
  #      * completion item. Characters that make up identifiers don't need to be listed here.
  #      *
  #      * If code complete should automatically be trigger on characters not being valid inside
  #      * an identifier (for example `.` in JavaScript) list them in `triggerCharacters`.
  #      */
  #     triggerCharacters?: string[];
  #     /**
  #      * The list of all possible characters that commit a completion. This field can be used
  #      * if clients don't support individual commmit characters per completion item. See
  #      * `ClientCapabilities.textDocument.completion.completionItem.commitCharactersSupport`
  #      *
  #      * If a server provides both `allCommitCharacters` and commit characters on an individual
  #      * completion item the ones on the completion item win.
  #      *
  #      * @since 3.2.0
  #      */
  #     allCommitCharacters?: string[];
  #     /**
  #      * The server provides support to resolve additional
  #      * information for a completion item.
  #      */
  #     resolveProvider?: boolean;
  # }
  class CompletionOptions < LSPBase
    attr_accessor :triggerCharacters, :allCommitCharacters, :resolveProvider, :workDoneProgress # type: string[] # type: string[] # type: boolean # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[triggerCharacters allCommitCharacters resolveProvider workDoneProgress]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.triggerCharacters = value['triggerCharacters'].map { |val| val } unless value['triggerCharacters'].nil?
      self.allCommitCharacters = value['allCommitCharacters'].map { |val| val } unless value['allCommitCharacters'].nil?
      self.resolveProvider = value['resolveProvider'] # Unknown type
      self.workDoneProgress = value['workDoneProgress'] # Unknown type
      self
    end
  end

  # export interface CompletionRegistrationOptions extends TextDocumentRegistrationOptions, CompletionOptions {
  # }
  class CompletionRegistrationOptions < LSPBase
    attr_accessor :documentSelector, :triggerCharacters, :allCommitCharacters, :resolveProvider, :workDoneProgress # type: DocumentSelector | null # type: string[] # type: string[] # type: boolean # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[triggerCharacters allCommitCharacters resolveProvider workDoneProgress]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.documentSelector = value['documentSelector'] # Unknown type
      self.triggerCharacters = value['triggerCharacters'].map { |val| val } unless value['triggerCharacters'].nil?
      self.allCommitCharacters = value['allCommitCharacters'].map { |val| val } unless value['allCommitCharacters'].nil?
      self.resolveProvider = value['resolveProvider'] # Unknown type
      self.workDoneProgress = value['workDoneProgress'] # Unknown type
      self
    end
  end

  # export interface HoverClientCapabilities {
  #     /**
  #      * Whether hover supports dynamic registration.
  #      */
  #     dynamicRegistration?: boolean;
  #     /**
  #      * Client supports the follow content formats for the content
  #      * property. The order describes the preferred format of the client.
  #      */
  #     contentFormat?: MarkupKind[];
  # }
  class HoverClientCapabilities < LSPBase
    attr_accessor :dynamicRegistration, :contentFormat # type: boolean # type: MarkupKind[]

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[dynamicRegistration contentFormat]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.dynamicRegistration = value['dynamicRegistration'] # Unknown type
      self.contentFormat = value['contentFormat'].map { |val| val } unless value['contentFormat'].nil? # Unknown array type
      self
    end
  end

  # export interface HoverOptions extends WorkDoneProgressOptions {
  # }
  class HoverOptions < LSPBase
    attr_accessor :workDoneProgress # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[workDoneProgress]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.workDoneProgress = value['workDoneProgress'] # Unknown type
      self
    end
  end

  # export interface HoverParams extends TextDocumentPositionParams, WorkDoneProgressParams {
  # }
  class HoverParams < LSPBase
    attr_accessor :textDocument, :position, :workDoneToken # type: TextDocumentIdentifier # type: Position # type: ProgressToken

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[workDoneToken]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = value['textDocument'] # Unknown type
      self.position = value['position'] # Unknown type
      self.workDoneToken = value['workDoneToken'] # Unknown type
      self
    end
  end

  # export interface HoverRegistrationOptions extends TextDocumentRegistrationOptions, HoverOptions {
  # }
  class HoverRegistrationOptions < LSPBase
    attr_accessor :documentSelector, :workDoneProgress # type: DocumentSelector | null # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[workDoneProgress]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.documentSelector = value['documentSelector'] # Unknown type
      self.workDoneProgress = value['workDoneProgress'] # Unknown type
      self
    end
  end

  # export interface SignatureHelpClientCapabilities {
  #     /**
  #      * Whether signature help supports dynamic registration.
  #      */
  #     dynamicRegistration?: boolean;
  #     /**
  #      * The client supports the following `SignatureInformation`
  #      * specific properties.
  #      */
  #     signatureInformation?: {
  #         /**
  #          * Client supports the follow content formats for the documentation
  #          * property. The order describes the preferred format of the client.
  #          */
  #         documentationFormat?: MarkupKind[];
  #         /**
  #          * Client capabilities specific to parameter information.
  #          */
  #         parameterInformation?: {
  #             /**
  #              * The client supports processing label offsets instead of a
  #              * simple label string.
  #              *
  #              * @since 3.14.0
  #              */
  #             labelOffsetSupport?: boolean;
  #         };
  #     };
  #     /**
  #      * The client supports to send additional context information for a
  #      * `textDocument/signatureHelp` request. A client that opts into
  #      * contextSupport will also support the `retriggerCharacters` on
  #      * `SignatureHelpOptions`.
  #      *
  #      * @since 3.15.0
  #      */
  #     contextSupport?: boolean;
  # }
  class SignatureHelpClientCapabilities < LSPBase
    attr_accessor :dynamicRegistration, :signatureInformation # type: boolean # type: {
    #        /**
    #         * Client supports the follow content formats for the documentation
    #         * property. The order describes the preferred format of the client.
    #         */
    #        documentationFormat?: MarkupKind[];
    #        /**
    #         * Client capabilities specific to parameter information.
    #         */
    #        parameterInformation?: {
    #            /**
    #             * The client supports processing label offsets instead of a
    #             * simple label string.
    #             *
    #             * @since 3.14.0
    #             */
    #            labelOffsetSupport?: boolean;
    #        };
    #    }
    attr_accessor :contextSupport # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[dynamicRegistration signatureInformation contextSupport]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.dynamicRegistration = value['dynamicRegistration'] # Unknown type
      self.signatureInformation = value['signatureInformation'] # Unknown type
      self.contextSupport = value['contextSupport'] # Unknown type
      self
    end
  end

  # export interface SignatureHelpOptions extends WorkDoneProgressOptions {
  #     /**
  #      * List of characters that trigger signature help.
  #      */
  #     triggerCharacters?: string[];
  #     /**
  #      * List of characters that re-trigger signature help.
  #      *
  #      * These trigger characters are only active when signature help is already showing. All trigger characters
  #      * are also counted as re-trigger characters.
  #      *
  #      * @since 3.15.0
  #      */
  #     retriggerCharacters?: string[];
  # }
  class SignatureHelpOptions < LSPBase
    attr_accessor :triggerCharacters, :retriggerCharacters, :workDoneProgress # type: string[] # type: string[] # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[triggerCharacters retriggerCharacters workDoneProgress]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.triggerCharacters = value['triggerCharacters'].map { |val| val } unless value['triggerCharacters'].nil?
      self.retriggerCharacters = value['retriggerCharacters'].map { |val| val } unless value['retriggerCharacters'].nil?
      self.workDoneProgress = value['workDoneProgress'] # Unknown type
      self
    end
  end

  # export interface SignatureHelpContext {
  #     /**
  #      * Action that caused signature help to be triggered.
  #      */
  #     triggerKind: SignatureHelpTriggerKind;
  #     /**
  #      * Character that caused signature help to be triggered.
  #      *
  #      * This is undefined when `triggerKind !== SignatureHelpTriggerKind.TriggerCharacter`
  #      */
  #     triggerCharacter?: string;
  #     /**
  #      * `true` if signature help was already showing when it was triggered.
  #      *
  #      * Retriggers occur when the signature help is already active and can be caused by actions such as
  #      * typing a trigger character, a cursor move, or document content changes.
  #      */
  #     isRetrigger: boolean;
  #     /**
  #      * The currently active `SignatureHelp`.
  #      *
  #      * The `activeSignatureHelp` has its `SignatureHelp.activeSignature` field updated based on
  #      * the user navigating through available signatures.
  #      */
  #     activeSignatureHelp?: SignatureHelp;
  # }
  class SignatureHelpContext < LSPBase
    attr_accessor :triggerKind, :triggerCharacter, :isRetrigger, :activeSignatureHelp # type: SignatureHelpTriggerKind # type: string # type: boolean # type: SignatureHelp

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[triggerCharacter activeSignatureHelp]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.triggerKind = value['triggerKind'] # Unknown type
      self.triggerCharacter = value['triggerCharacter']
      self.isRetrigger = value['isRetrigger'] # Unknown type
      self.activeSignatureHelp = value['activeSignatureHelp'] # Unknown type
      self
    end
  end

  # export interface SignatureHelpParams extends TextDocumentPositionParams, WorkDoneProgressParams {
  #     /**
  #      * The signature help context. This is only available if the client specifies
  #      * to send this using the client capability `textDocument.signatureHelp.contextSupport === true`
  #      *
  #      * @since 3.15.0
  #      */
  #     context?: SignatureHelpContext;
  # }
  class SignatureHelpParams < LSPBase
    attr_accessor :context, :textDocument, :position, :workDoneToken # type: SignatureHelpContext # type: TextDocumentIdentifier # type: Position # type: ProgressToken

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[context workDoneToken]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.context = SignatureHelpContext.new(value['context']) unless value['context'].nil?
      self.textDocument = value['textDocument'] # Unknown type
      self.position = value['position'] # Unknown type
      self.workDoneToken = value['workDoneToken'] # Unknown type
      self
    end
  end

  # export interface SignatureHelpRegistrationOptions extends TextDocumentRegistrationOptions, SignatureHelpOptions {
  # }
  class SignatureHelpRegistrationOptions < LSPBase
    attr_accessor :documentSelector, :triggerCharacters, :retriggerCharacters, :workDoneProgress # type: DocumentSelector | null # type: string[] # type: string[] # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[triggerCharacters retriggerCharacters workDoneProgress]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.documentSelector = value['documentSelector'] # Unknown type
      self.triggerCharacters = value['triggerCharacters'].map { |val| val } unless value['triggerCharacters'].nil?
      self.retriggerCharacters = value['retriggerCharacters'].map { |val| val } unless value['retriggerCharacters'].nil?
      self.workDoneProgress = value['workDoneProgress'] # Unknown type
      self
    end
  end

  # export interface DefinitionClientCapabilities {
  #     /**
  #      * Whether definition supports dynamic registration.
  #      */
  #     dynamicRegistration?: boolean;
  #     /**
  #      * The client supports additional metadata in the form of definition links.
  #      *
  #      * @since 3.14.0
  #      */
  #     linkSupport?: boolean;
  # }
  class DefinitionClientCapabilities < LSPBase
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

  # export interface DefinitionOptions extends WorkDoneProgressOptions {
  # }
  class DefinitionOptions < LSPBase
    attr_accessor :workDoneProgress # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[workDoneProgress]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.workDoneProgress = value['workDoneProgress'] # Unknown type
      self
    end
  end

  # export interface DefinitionParams extends TextDocumentPositionParams, WorkDoneProgressParams, PartialResultParams {
  # }
  class DefinitionParams < LSPBase
    attr_accessor :textDocument, :position, :workDoneToken, :partialResultToken # type: TextDocumentIdentifier # type: Position # type: ProgressToken # type: ProgressToken

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[workDoneToken partialResultToken]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = value['textDocument'] # Unknown type
      self.position = value['position'] # Unknown type
      self.workDoneToken = value['workDoneToken'] # Unknown type
      self.partialResultToken = value['partialResultToken'] # Unknown type
      self
    end
  end

  # export interface DefinitionRegistrationOptions extends TextDocumentRegistrationOptions, DefinitionOptions {
  # }
  class DefinitionRegistrationOptions < LSPBase
    attr_accessor :documentSelector, :workDoneProgress # type: DocumentSelector | null # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[workDoneProgress]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.documentSelector = value['documentSelector'] # Unknown type
      self.workDoneProgress = value['workDoneProgress'] # Unknown type
      self
    end
  end

  # export interface ReferenceClientCapabilities {
  #     /**
  #      * Whether references supports dynamic registration.
  #      */
  #     dynamicRegistration?: boolean;
  # }
  class ReferenceClientCapabilities < LSPBase
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

  # export interface ReferenceParams extends TextDocumentPositionParams, WorkDoneProgressParams, PartialResultParams {
  #     context: ReferenceContext;
  # }
  class ReferenceParams < LSPBase
    attr_accessor :context, :textDocument, :position, :workDoneToken, :partialResultToken # type: ReferenceContext # type: TextDocumentIdentifier # type: Position # type: ProgressToken # type: ProgressToken

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[workDoneToken partialResultToken]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.context = value['context'] # Unknown type
      self.textDocument = value['textDocument'] # Unknown type
      self.position = value['position'] # Unknown type
      self.workDoneToken = value['workDoneToken'] # Unknown type
      self.partialResultToken = value['partialResultToken'] # Unknown type
      self
    end
  end

  # export interface ReferenceOptions extends WorkDoneProgressOptions {
  # }
  class ReferenceOptions < LSPBase
    attr_accessor :workDoneProgress # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[workDoneProgress]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.workDoneProgress = value['workDoneProgress'] # Unknown type
      self
    end
  end

  # export interface ReferenceRegistrationOptions extends TextDocumentRegistrationOptions, ReferenceOptions {
  # }
  class ReferenceRegistrationOptions < LSPBase
    attr_accessor :documentSelector, :workDoneProgress # type: DocumentSelector | null # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[workDoneProgress]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.documentSelector = value['documentSelector'] # Unknown type
      self.workDoneProgress = value['workDoneProgress'] # Unknown type
      self
    end
  end

  # export interface DocumentHighlightClientCapabilities {
  #     /**
  #      * Whether document highlight supports dynamic registration.
  #      */
  #     dynamicRegistration?: boolean;
  # }
  class DocumentHighlightClientCapabilities < LSPBase
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

  # export interface DocumentHighlightParams extends TextDocumentPositionParams, WorkDoneProgressParams, PartialResultParams {
  # }
  class DocumentHighlightParams < LSPBase
    attr_accessor :textDocument, :position, :workDoneToken, :partialResultToken # type: TextDocumentIdentifier # type: Position # type: ProgressToken # type: ProgressToken

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[workDoneToken partialResultToken]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = value['textDocument'] # Unknown type
      self.position = value['position'] # Unknown type
      self.workDoneToken = value['workDoneToken'] # Unknown type
      self.partialResultToken = value['partialResultToken'] # Unknown type
      self
    end
  end

  # export interface DocumentHighlightOptions extends WorkDoneProgressOptions {
  # }
  class DocumentHighlightOptions < LSPBase
    attr_accessor :workDoneProgress # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[workDoneProgress]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.workDoneProgress = value['workDoneProgress'] # Unknown type
      self
    end
  end

  # export interface DocumentHighlightRegistrationOptions extends TextDocumentRegistrationOptions, DocumentHighlightOptions {
  # }
  class DocumentHighlightRegistrationOptions < LSPBase
    attr_accessor :documentSelector, :workDoneProgress # type: DocumentSelector | null # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[workDoneProgress]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.documentSelector = value['documentSelector'] # Unknown type
      self.workDoneProgress = value['workDoneProgress'] # Unknown type
      self
    end
  end

  # export interface DocumentSymbolClientCapabilities {
  #     /**
  #      * Whether document symbol supports dynamic registration.
  #      */
  #     dynamicRegistration?: boolean;
  #     /**
  #      * Specific capabilities for the `SymbolKind`.
  #      */
  #     symbolKind?: {
  #         /**
  #          * The symbol kind values the client supports. When this
  #          * property exists the client also guarantees that it will
  #          * handle values outside its set gracefully and falls back
  #          * to a default value when unknown.
  #          *
  #          * If this property is not present the client only supports
  #          * the symbol kinds from `File` to `Array` as defined in
  #          * the initial version of the protocol.
  #          */
  #         valueSet?: SymbolKind[];
  #     };
  #     /**
  #      * The client support hierarchical document symbols.
  #      */
  #     hierarchicalDocumentSymbolSupport?: boolean;
  # }
  class DocumentSymbolClientCapabilities < LSPBase
    attr_accessor :dynamicRegistration, :symbolKind # type: boolean # type: {
    #        /**
    #         * The symbol kind values the client supports. When this
    #         * property exists the client also guarantees that it will
    #         * handle values outside its set gracefully and falls back
    #         * to a default value when unknown.
    #         *
    #         * If this property is not present the client only supports
    #         * the symbol kinds from `File` to `Array` as defined in
    #         * the initial version of the protocol.
    #         */
    #        valueSet?: SymbolKind[];
    #    }
    attr_accessor :hierarchicalDocumentSymbolSupport # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[dynamicRegistration symbolKind hierarchicalDocumentSymbolSupport]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.dynamicRegistration = value['dynamicRegistration'] # Unknown type
      self.symbolKind = value['symbolKind'] # Unknown type
      self.hierarchicalDocumentSymbolSupport = value['hierarchicalDocumentSymbolSupport'] # Unknown type
      self
    end
  end

  # export interface DocumentSymbolParams extends WorkDoneProgressParams, PartialResultParams {
  #     /**
  #      * The text document.
  #      */
  #     textDocument: TextDocumentIdentifier;
  # }
  class DocumentSymbolParams < LSPBase
    attr_accessor :textDocument, :workDoneToken, :partialResultToken # type: TextDocumentIdentifier # type: ProgressToken # type: ProgressToken

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[workDoneToken partialResultToken]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = value['textDocument'] # Unknown type
      self.workDoneToken = value['workDoneToken'] # Unknown type
      self.partialResultToken = value['partialResultToken'] # Unknown type
      self
    end
  end

  # export interface DocumentSymbolOptions extends WorkDoneProgressOptions {
  # }
  class DocumentSymbolOptions < LSPBase
    attr_accessor :workDoneProgress # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[workDoneProgress]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.workDoneProgress = value['workDoneProgress'] # Unknown type
      self
    end
  end

  # export interface DocumentSymbolRegistrationOptions extends TextDocumentRegistrationOptions, DocumentSymbolOptions {
  # }
  class DocumentSymbolRegistrationOptions < LSPBase
    attr_accessor :documentSelector, :workDoneProgress # type: DocumentSelector | null # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[workDoneProgress]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.documentSelector = value['documentSelector'] # Unknown type
      self.workDoneProgress = value['workDoneProgress'] # Unknown type
      self
    end
  end

  # export interface CodeActionClientCapabilities {
  #     /**
  #      * Whether code action supports dynamic registration.
  #      */
  #     dynamicRegistration?: boolean;
  #     /**
  #      * The client support code action literals as a valid
  #      * response of the `textDocument/codeAction` request.
  #      *
  #      * @since 3.8.0
  #      */
  #     codeActionLiteralSupport?: {
  #         /**
  #          * The code action kind is support with the following value
  #          * set.
  #          */
  #         codeActionKind: {
  #             /**
  #              * The code action kind values the client supports. When this
  #              * property exists the client also guarantees that it will
  #              * handle values outside its set gracefully and falls back
  #              * to a default value when unknown.
  #              */
  #             valueSet: CodeActionKind[];
  #         };
  #     };
  #     /**
  #      * Whether code action supports the `isPreferred` property.
  #      * @since 3.15.0
  #      */
  #     isPreferredSupport?: boolean;
  # }
  class CodeActionClientCapabilities < LSPBase
    attr_accessor :dynamicRegistration, :codeActionLiteralSupport # type: boolean # type: {
    #        /**
    #         * The code action kind is support with the following value
    #         * set.
    #         */
    #        codeActionKind: {
    #            /**
    #             * The code action kind values the client supports. When this
    #             * property exists the client also guarantees that it will
    #             * handle values outside its set gracefully and falls back
    #             * to a default value when unknown.
    #             */
    #            valueSet: CodeActionKind[];
    #        };
    #    }
    attr_accessor :isPreferredSupport # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[dynamicRegistration codeActionLiteralSupport isPreferredSupport]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.dynamicRegistration = value['dynamicRegistration'] # Unknown type
      self.codeActionLiteralSupport = value['codeActionLiteralSupport'] # Unknown type
      self.isPreferredSupport = value['isPreferredSupport'] # Unknown type
      self
    end
  end

  # export interface CodeActionParams extends WorkDoneProgressParams, PartialResultParams {
  #     /**
  #      * The document in which the command was invoked.
  #      */
  #     textDocument: TextDocumentIdentifier;
  #     /**
  #      * The range for which the command was invoked.
  #      */
  #     range: Range;
  #     /**
  #      * Context carrying additional information.
  #      */
  #     context: CodeActionContext;
  # }
  class CodeActionParams < LSPBase
    attr_accessor :textDocument, :range, :context, :workDoneToken, :partialResultToken # type: TextDocumentIdentifier # type: Range # type: CodeActionContext # type: ProgressToken # type: ProgressToken

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[workDoneToken partialResultToken]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = value['textDocument'] # Unknown type
      self.range = value['range'] # Unknown type
      self.context = value['context'] # Unknown type
      self.workDoneToken = value['workDoneToken'] # Unknown type
      self.partialResultToken = value['partialResultToken'] # Unknown type
      self
    end
  end

  # export interface CodeActionOptions extends WorkDoneProgressOptions {
  #     /**
  #      * CodeActionKinds that this server may return.
  #      *
  #      * The list of kinds may be generic, such as `CodeActionKind.Refactor`, or the server
  #      * may list out every specific kind they provide.
  #      */
  #     codeActionKinds?: CodeActionKind[];
  # }
  class CodeActionOptions < LSPBase
    attr_accessor :codeActionKinds, :workDoneProgress # type: CodeActionKind[] # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[codeActionKinds workDoneProgress]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.codeActionKinds = value['codeActionKinds'].map { |val| val } unless value['codeActionKinds'].nil? # Unknown array type
      self.workDoneProgress = value['workDoneProgress'] # Unknown type
      self
    end
  end

  # export interface CodeActionRegistrationOptions extends TextDocumentRegistrationOptions, CodeActionOptions {
  # }
  class CodeActionRegistrationOptions < LSPBase
    attr_accessor :documentSelector, :codeActionKinds, :workDoneProgress # type: DocumentSelector | null # type: CodeActionKind[] # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[codeActionKinds workDoneProgress]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.documentSelector = value['documentSelector'] # Unknown type
      self.codeActionKinds = value['codeActionKinds'].map { |val| val } unless value['codeActionKinds'].nil? # Unknown array type
      self.workDoneProgress = value['workDoneProgress'] # Unknown type
      self
    end
  end

  # export interface WorkspaceSymbolClientCapabilities {
  #     /**
  #      * Symbol request supports dynamic registration.
  #      */
  #     dynamicRegistration?: boolean;
  #     /**
  #      * Specific capabilities for the `SymbolKind` in the `workspace/symbol` request.
  #      */
  #     symbolKind?: {
  #         /**
  #          * The symbol kind values the client supports. When this
  #          * property exists the client also guarantees that it will
  #          * handle values outside its set gracefully and falls back
  #          * to a default value when unknown.
  #          *
  #          * If this property is not present the client only supports
  #          * the symbol kinds from `File` to `Array` as defined in
  #          * the initial version of the protocol.
  #          */
  #         valueSet?: SymbolKind[];
  #     };
  # }
  class WorkspaceSymbolClientCapabilities < LSPBase
    attr_accessor :dynamicRegistration, :symbolKind # type: boolean # type: {

    #        /**
    #         * The symbol kind values the client supports. When this
    #         * property exists the client also guarantees that it will
    #         * handle values outside its set gracefully and falls back
    #         * to a default value when unknown.
    #         *
    #         * If this property is not present the client only supports
    #         * the symbol kinds from `File` to `Array` as defined in
    #         * the initial version of the protocol.
    #         */
    #        valueSet?: SymbolKind[];
    #    }

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[dynamicRegistration symbolKind]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.dynamicRegistration = value['dynamicRegistration'] # Unknown type
      self.symbolKind = value['symbolKind'] # Unknown type
      self
    end
  end

  # export interface WorkspaceSymbolParams extends WorkDoneProgressParams, PartialResultParams {
  #     /**
  #      * A query string to filter symbols by. Clients may send an empty
  #      * string here to request all symbols.
  #      */
  #     query: string;
  # }
  class WorkspaceSymbolParams < LSPBase
    attr_accessor :query, :workDoneToken, :partialResultToken # type: string # type: ProgressToken # type: ProgressToken

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[workDoneToken partialResultToken]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.query = value['query']
      self.workDoneToken = value['workDoneToken'] # Unknown type
      self.partialResultToken = value['partialResultToken'] # Unknown type
      self
    end
  end

  # export interface WorkspaceSymbolOptions extends WorkDoneProgressOptions {
  # }
  class WorkspaceSymbolOptions < LSPBase
    attr_accessor :workDoneProgress # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[workDoneProgress]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.workDoneProgress = value['workDoneProgress'] # Unknown type
      self
    end
  end

  # export interface WorkspaceSymbolRegistrationOptions extends WorkspaceSymbolOptions {
  # }
  class WorkspaceSymbolRegistrationOptions < LSPBase
    attr_accessor :workDoneProgress # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[workDoneProgress]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.workDoneProgress = value['workDoneProgress'] # Unknown type
      self
    end
  end

  # export interface CodeLensClientCapabilities {
  #     /**
  #      * Whether code lens supports dynamic registration.
  #      */
  #     dynamicRegistration?: boolean;
  # }
  class CodeLensClientCapabilities < LSPBase
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

  # export interface CodeLensParams extends WorkDoneProgressParams, PartialResultParams {
  #     /**
  #      * The document to request code lens for.
  #      */
  #     textDocument: TextDocumentIdentifier;
  # }
  class CodeLensParams < LSPBase
    attr_accessor :textDocument, :workDoneToken, :partialResultToken # type: TextDocumentIdentifier # type: ProgressToken # type: ProgressToken

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[workDoneToken partialResultToken]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = value['textDocument'] # Unknown type
      self.workDoneToken = value['workDoneToken'] # Unknown type
      self.partialResultToken = value['partialResultToken'] # Unknown type
      self
    end
  end

  # export interface CodeLensOptions extends WorkDoneProgressOptions {
  #     /**
  #      * Code lens has a resolve provider as well.
  #      */
  #     resolveProvider?: boolean;
  # }
  class CodeLensOptions < LSPBase
    attr_accessor :resolveProvider, :workDoneProgress # type: boolean # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[resolveProvider workDoneProgress]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.resolveProvider = value['resolveProvider'] # Unknown type
      self.workDoneProgress = value['workDoneProgress'] # Unknown type
      self
    end
  end

  # export interface CodeLensRegistrationOptions extends TextDocumentRegistrationOptions, CodeLensOptions {
  # }
  class CodeLensRegistrationOptions < LSPBase
    attr_accessor :documentSelector, :resolveProvider, :workDoneProgress # type: DocumentSelector | null # type: boolean # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[resolveProvider workDoneProgress]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.documentSelector = value['documentSelector'] # Unknown type
      self.resolveProvider = value['resolveProvider'] # Unknown type
      self.workDoneProgress = value['workDoneProgress'] # Unknown type
      self
    end
  end

  # export interface DocumentLinkClientCapabilities {
  #     /**
  #      * Whether document link supports dynamic registration.
  #      */
  #     dynamicRegistration?: boolean;
  #     /**
  #      * Whether the client support the `tooltip` property on `DocumentLink`.
  #      *
  #      * @since 3.15.0
  #      */
  #     tooltipSupport?: boolean;
  # }
  class DocumentLinkClientCapabilities < LSPBase
    attr_accessor :dynamicRegistration, :tooltipSupport # type: boolean # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[dynamicRegistration tooltipSupport]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.dynamicRegistration = value['dynamicRegistration'] # Unknown type
      self.tooltipSupport = value['tooltipSupport'] # Unknown type
      self
    end
  end

  # export interface DocumentLinkParams extends WorkDoneProgressParams, PartialResultParams {
  #     /**
  #      * The document to provide document links for.
  #      */
  #     textDocument: TextDocumentIdentifier;
  # }
  class DocumentLinkParams < LSPBase
    attr_accessor :textDocument, :workDoneToken, :partialResultToken # type: TextDocumentIdentifier # type: ProgressToken # type: ProgressToken

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[workDoneToken partialResultToken]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = value['textDocument'] # Unknown type
      self.workDoneToken = value['workDoneToken'] # Unknown type
      self.partialResultToken = value['partialResultToken'] # Unknown type
      self
    end
  end

  # export interface DocumentLinkOptions extends WorkDoneProgressOptions {
  #     /**
  #      * Document links have a resolve provider as well.
  #      */
  #     resolveProvider?: boolean;
  # }
  class DocumentLinkOptions < LSPBase
    attr_accessor :resolveProvider, :workDoneProgress # type: boolean # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[resolveProvider workDoneProgress]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.resolveProvider = value['resolveProvider'] # Unknown type
      self.workDoneProgress = value['workDoneProgress'] # Unknown type
      self
    end
  end

  # export interface DocumentLinkRegistrationOptions extends TextDocumentRegistrationOptions, DocumentLinkOptions {
  # }
  class DocumentLinkRegistrationOptions < LSPBase
    attr_accessor :documentSelector, :resolveProvider, :workDoneProgress # type: DocumentSelector | null # type: boolean # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[resolveProvider workDoneProgress]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.documentSelector = value['documentSelector'] # Unknown type
      self.resolveProvider = value['resolveProvider'] # Unknown type
      self.workDoneProgress = value['workDoneProgress'] # Unknown type
      self
    end
  end

  # export interface DocumentFormattingClientCapabilities {
  #     /**
  #      * Whether formatting supports dynamic registration.
  #      */
  #     dynamicRegistration?: boolean;
  # }
  class DocumentFormattingClientCapabilities < LSPBase
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

  # export interface DocumentFormattingParams extends WorkDoneProgressParams {
  #     /**
  #      * The document to format.
  #      */
  #     textDocument: TextDocumentIdentifier;
  #     /**
  #      * The format options
  #      */
  #     options: FormattingOptions;
  # }
  class DocumentFormattingParams < LSPBase
    attr_accessor :textDocument, :options, :workDoneToken # type: TextDocumentIdentifier # type: FormattingOptions # type: ProgressToken

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[workDoneToken]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = value['textDocument'] # Unknown type
      self.options = value['options'] # Unknown type
      self.workDoneToken = value['workDoneToken'] # Unknown type
      self
    end
  end

  # export interface DocumentFormattingOptions extends WorkDoneProgressOptions {
  # }
  class DocumentFormattingOptions < LSPBase
    attr_accessor :workDoneProgress # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[workDoneProgress]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.workDoneProgress = value['workDoneProgress'] # Unknown type
      self
    end
  end

  # export interface DocumentFormattingRegistrationOptions extends TextDocumentRegistrationOptions, DocumentFormattingOptions {
  # }
  class DocumentFormattingRegistrationOptions < LSPBase
    attr_accessor :documentSelector, :workDoneProgress # type: DocumentSelector | null # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[workDoneProgress]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.documentSelector = value['documentSelector'] # Unknown type
      self.workDoneProgress = value['workDoneProgress'] # Unknown type
      self
    end
  end

  # export interface DocumentRangeFormattingClientCapabilities {
  #     /**
  #      * Whether range formatting supports dynamic registration.
  #      */
  #     dynamicRegistration?: boolean;
  # }
  class DocumentRangeFormattingClientCapabilities < LSPBase
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

  # export interface DocumentRangeFormattingParams extends WorkDoneProgressParams {
  #     /**
  #      * The document to format.
  #      */
  #     textDocument: TextDocumentIdentifier;
  #     /**
  #      * The range to format
  #      */
  #     range: Range;
  #     /**
  #      * The format options
  #      */
  #     options: FormattingOptions;
  # }
  class DocumentRangeFormattingParams < LSPBase
    attr_accessor :textDocument, :range, :options, :workDoneToken # type: TextDocumentIdentifier # type: Range # type: FormattingOptions # type: ProgressToken

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[workDoneToken]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = value['textDocument'] # Unknown type
      self.range = value['range'] # Unknown type
      self.options = value['options'] # Unknown type
      self.workDoneToken = value['workDoneToken'] # Unknown type
      self
    end
  end

  # export interface DocumentRangeFormattingOptions extends WorkDoneProgressOptions {
  # }
  class DocumentRangeFormattingOptions < LSPBase
    attr_accessor :workDoneProgress # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[workDoneProgress]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.workDoneProgress = value['workDoneProgress'] # Unknown type
      self
    end
  end

  # export interface DocumentRangeFormattingRegistrationOptions extends TextDocumentRegistrationOptions, DocumentRangeFormattingOptions {
  # }
  class DocumentRangeFormattingRegistrationOptions < LSPBase
    attr_accessor :documentSelector, :workDoneProgress # type: DocumentSelector | null # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[workDoneProgress]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.documentSelector = value['documentSelector'] # Unknown type
      self.workDoneProgress = value['workDoneProgress'] # Unknown type
      self
    end
  end

  # export interface DocumentOnTypeFormattingClientCapabilities {
  #     /**
  #      * Whether on type formatting supports dynamic registration.
  #      */
  #     dynamicRegistration?: boolean;
  # }
  class DocumentOnTypeFormattingClientCapabilities < LSPBase
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

  # export interface DocumentOnTypeFormattingParams {
  #     /**
  #      * The document to format.
  #      */
  #     textDocument: TextDocumentIdentifier;
  #     /**
  #      * The position at which this request was send.
  #      */
  #     position: Position;
  #     /**
  #      * The character that has been typed.
  #      */
  #     ch: string;
  #     /**
  #      * The format options.
  #      */
  #     options: FormattingOptions;
  # }
  class DocumentOnTypeFormattingParams < LSPBase
    attr_accessor :textDocument, :position, :ch, :options # type: TextDocumentIdentifier # type: Position # type: string # type: FormattingOptions

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = value['textDocument'] # Unknown type
      self.position = value['position'] # Unknown type
      self.ch = value['ch']
      self.options = value['options'] # Unknown type
      self
    end
  end

  # export interface DocumentOnTypeFormattingOptions {
  #     /**
  #      * A character on which formatting should be triggered, like `}`.
  #      */
  #     firstTriggerCharacter: string;
  #     /**
  #      * More trigger characters.
  #      */
  #     moreTriggerCharacter?: string[];
  # }
  class DocumentOnTypeFormattingOptions < LSPBase
    attr_accessor :firstTriggerCharacter, :moreTriggerCharacter # type: string # type: string[]

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[moreTriggerCharacter]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.firstTriggerCharacter = value['firstTriggerCharacter']
      self.moreTriggerCharacter = value['moreTriggerCharacter'].map { |val| val } unless value['moreTriggerCharacter'].nil?
      self
    end
  end

  # export interface DocumentOnTypeFormattingRegistrationOptions extends TextDocumentRegistrationOptions, DocumentOnTypeFormattingOptions {
  # }
  class DocumentOnTypeFormattingRegistrationOptions < LSPBase
    attr_accessor :documentSelector, :firstTriggerCharacter, :moreTriggerCharacter # type: DocumentSelector | null # type: string # type: string[]

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[moreTriggerCharacter]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.documentSelector = value['documentSelector'] # Unknown type
      self.firstTriggerCharacter = value['firstTriggerCharacter']
      self.moreTriggerCharacter = value['moreTriggerCharacter'].map { |val| val } unless value['moreTriggerCharacter'].nil?
      self
    end
  end

  # export interface RenameClientCapabilities {
  #     /**
  #      * Whether rename supports dynamic registration.
  #      */
  #     dynamicRegistration?: boolean;
  #     /**
  #      * Client supports testing for validity of rename operations
  #      * before execution.
  #      *
  #      * @since version 3.12.0
  #      */
  #     prepareSupport?: boolean;
  # }
  class RenameClientCapabilities < LSPBase
    attr_accessor :dynamicRegistration, :prepareSupport # type: boolean # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[dynamicRegistration prepareSupport]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.dynamicRegistration = value['dynamicRegistration'] # Unknown type
      self.prepareSupport = value['prepareSupport'] # Unknown type
      self
    end
  end

  # export interface RenameParams extends WorkDoneProgressParams {
  #     /**
  #      * The document to rename.
  #      */
  #     textDocument: TextDocumentIdentifier;
  #     /**
  #      * The position at which this request was sent.
  #      */
  #     position: Position;
  #     /**
  #      * The new name of the symbol. If the given name is not valid the
  #      * request must return a [ResponseError](#ResponseError) with an
  #      * appropriate message set.
  #      */
  #     newName: string;
  # }
  class RenameParams < LSPBase
    attr_accessor :textDocument, :position, :newName, :workDoneToken # type: TextDocumentIdentifier # type: Position # type: string # type: ProgressToken

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[workDoneToken]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = value['textDocument'] # Unknown type
      self.position = value['position'] # Unknown type
      self.newName = value['newName']
      self.workDoneToken = value['workDoneToken'] # Unknown type
      self
    end
  end

  # export interface RenameOptions extends WorkDoneProgressOptions {
  #     /**
  #      * Renames should be checked and tested before being executed.
  #      *
  #      * @since version 3.12.0
  #      */
  #     prepareProvider?: boolean;
  # }
  class RenameOptions < LSPBase
    attr_accessor :prepareProvider, :workDoneProgress # type: boolean # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[prepareProvider workDoneProgress]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.prepareProvider = value['prepareProvider'] # Unknown type
      self.workDoneProgress = value['workDoneProgress'] # Unknown type
      self
    end
  end

  # export interface RenameRegistrationOptions extends TextDocumentRegistrationOptions, RenameOptions {
  # }
  class RenameRegistrationOptions < LSPBase
    attr_accessor :documentSelector, :prepareProvider, :workDoneProgress # type: DocumentSelector | null # type: boolean # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[prepareProvider workDoneProgress]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.documentSelector = value['documentSelector'] # Unknown type
      self.prepareProvider = value['prepareProvider'] # Unknown type
      self.workDoneProgress = value['workDoneProgress'] # Unknown type
      self
    end
  end

  # export interface PrepareRenameParams extends TextDocumentPositionParams, WorkDoneProgressParams {
  # }
  class PrepareRenameParams < LSPBase
    attr_accessor :textDocument, :position, :workDoneToken # type: TextDocumentIdentifier # type: Position # type: ProgressToken

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[workDoneToken]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = value['textDocument'] # Unknown type
      self.position = value['position'] # Unknown type
      self.workDoneToken = value['workDoneToken'] # Unknown type
      self
    end
  end

  # export interface ExecuteCommandClientCapabilities {
  #     /**
  #      * Execute command supports dynamic registration.
  #      */
  #     dynamicRegistration?: boolean;
  # }
  class ExecuteCommandClientCapabilities < LSPBase
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

  # export interface ExecuteCommandParams extends WorkDoneProgressParams {
  #     /**
  #      * The identifier of the actual command handler.
  #      */
  #     command: string;
  #     /**
  #      * Arguments that the command should be invoked with.
  #      */
  #     arguments?: any[];
  # }
  class ExecuteCommandParams < LSPBase
    attr_accessor :command, :arguments, :workDoneToken # type: string # type: any[] # type: ProgressToken

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[arguments workDoneToken]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.command = value['command']
      self.arguments = value['arguments'].map { |val| val } unless value['arguments'].nil?
      self.workDoneToken = value['workDoneToken'] # Unknown type
      self
    end
  end

  # export interface ExecuteCommandOptions extends WorkDoneProgressOptions {
  #     /**
  #      * The commands to be executed on the server
  #      */
  #     commands: string[];
  # }
  class ExecuteCommandOptions < LSPBase
    attr_accessor :commands, :workDoneProgress # type: string[] # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[workDoneProgress]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.commands = value['commands'].map { |val| val } unless value['commands'].nil?
      self.workDoneProgress = value['workDoneProgress'] # Unknown type
      self
    end
  end

  # export interface ExecuteCommandRegistrationOptions extends ExecuteCommandOptions {
  # }
  class ExecuteCommandRegistrationOptions < LSPBase
    attr_accessor :commands, :workDoneProgress # type: string[] # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[workDoneProgress]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.commands = value['commands'].map { |val| val } unless value['commands'].nil?
      self.workDoneProgress = value['workDoneProgress'] # Unknown type
      self
    end
  end

  # export interface WorkspaceEditClientCapabilities {
  #     /**
  #      * The client supports versioned document changes in `WorkspaceEdit`s
  #      */
  #     documentChanges?: boolean;
  #     /**
  #      * The resource operations the client supports. Clients should at least
  #      * support 'create', 'rename' and 'delete' files and folders.
  #      *
  #      * @since 3.13.0
  #      */
  #     resourceOperations?: ResourceOperationKind[];
  #     /**
  #      * The failure handling strategy of a client if applying the workspace edit
  #      * fails.
  #      *
  #      * @since 3.13.0
  #      */
  #     failureHandling?: FailureHandlingKind;
  # }
  class WorkspaceEditClientCapabilities < LSPBase
    attr_accessor :documentChanges, :resourceOperations, :failureHandling # type: boolean # type: ResourceOperationKind[] # type: FailureHandlingKind

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[documentChanges resourceOperations failureHandling]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.documentChanges = value['documentChanges'] # Unknown type
      self.resourceOperations = value['resourceOperations'].map { |val| val } unless value['resourceOperations'].nil? # Unknown array type
      self.failureHandling = value['failureHandling'] # Unknown type
      self
    end
  end

  # export interface ApplyWorkspaceEditParams {
  #     /**
  #      * An optional label of the workspace edit. This label is
  #      * presented in the user interface for example on an undo
  #      * stack to undo the workspace edit.
  #      */
  #     label?: string;
  #     /**
  #      * The edits to apply.
  #      */
  #     edit: WorkspaceEdit;
  # }
  class ApplyWorkspaceEditParams < LSPBase
    attr_accessor :label, :edit # type: string # type: WorkspaceEdit

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[label]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.label = value['label']
      self.edit = value['edit'] # Unknown type
      self
    end
  end

  # export interface ApplyWorkspaceEditResponse {
  #     /**
  #      * Indicates whether the edit was applied or not.
  #      */
  #     applied: boolean;
  #     /**
  #      * An optional textual description for why the edit was not applied.
  #      * This may be used by the server for diagnostic logging or to provide
  #      * a suitable error for a request that triggered the edit.
  #      */
  #     failureReason?: string;
  #     /**
  #      * Depending on the client's failure handling strategy `failedChange` might
  #      * contain the index of the change that failed. This property is only available
  #      * if the client signals a `failureHandlingStrategy` in its client capabilities.
  #      */
  #     failedChange?: number;
  # }
  class ApplyWorkspaceEditResponse < LSPBase
    attr_accessor :applied, :failureReason, :failedChange # type: boolean # type: string # type: number

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[failureReason failedChange]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.applied = value['applied'] # Unknown type
      self.failureReason = value['failureReason']
      self.failedChange = value['failedChange']
      self
    end
  end
end

# rubocop:enable Layout/EmptyLinesAroundClassBody
# rubocop:enable Lint/UselessAssignment
# rubocop:enable Style/AsciiComments
# rubocop:enable Naming/MethodName
