# frozen_string_literal: true

# DO NOT MODIFY. This file is built automatically
# LSP Protocol: vscode-languageserver-protocol/lib/protocol.d.ts

# rubocop:disable Layout/EmptyLinesAroundClassBody
# rubocop:disable Lint/UselessAssignment
# rubocop:disable Style/AsciiComments

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
    attr_accessor :id # type: string
    attr_accessor :method__lsp # type: string
    attr_accessor :registerOptions # type: any

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
    attr_accessor :id # type: string
    attr_accessor :method__lsp # type: string

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
    attr_accessor :textDocument # type: TextDocumentIdentifier
    attr_accessor :position # type: Position

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

  # export interface CompletionOptions {
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
  #      * The server provides support to resolve additional
  #      * information for a completion item.
  #      */
  #     resolveProvider?: boolean;
  # }
  class CompletionOptions < LSPBase
    attr_accessor :triggerCharacters # type: string[]
    attr_accessor :resolveProvider # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[triggerCharacters resolveProvider]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.triggerCharacters = value['triggerCharacters'].map { |val| val } unless value['triggerCharacters'].nil?
      self.resolveProvider = value['resolveProvider'] # Unknown type
      self
    end
  end

  # export interface SignatureHelpOptions {
  #     /**
  #      * The characters that trigger signature help
  #      * automatically.
  #      */
  #     triggerCharacters?: string[];
  # }
  class SignatureHelpOptions < LSPBase
    attr_accessor :triggerCharacters # type: string[]

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[triggerCharacters]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.triggerCharacters = value['triggerCharacters'].map { |val| val } unless value['triggerCharacters'].nil?
      self
    end
  end

  # export interface CodeActionOptions {
  #     /**
  #      * CodeActionKinds that this server may return.
  #      *
  #      * The list of kinds may be generic, such as `CodeActionKind.Refactor`, or the server
  #      * may list out every specific kind they provide.
  #      */
  #     codeActionKinds?: CodeActionKind[];
  # }
  class CodeActionOptions < LSPBase
    attr_accessor :codeActionKinds # type: CodeActionKind[]

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[codeActionKinds]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.codeActionKinds = value['codeActionKinds'].map { |val| val } unless value['codeActionKinds'].nil? # Unknown array type
      self
    end
  end

  # export interface CodeLensOptions {
  #     /**
  #      * Code lens has a resolve provider as well.
  #      */
  #     resolveProvider?: boolean;
  # }
  class CodeLensOptions < LSPBase
    attr_accessor :resolveProvider # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[resolveProvider]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.resolveProvider = value['resolveProvider'] # Unknown type
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
    attr_accessor :firstTriggerCharacter # type: string
    attr_accessor :moreTriggerCharacter # type: string[]

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

  # export interface RenameOptions {
  #     /**
  #      * Renames should be checked and tested before being executed.
  #      */
  #     prepareProvider?: boolean;
  # }
  class RenameOptions < LSPBase
    attr_accessor :prepareProvider # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[prepareProvider]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.prepareProvider = value['prepareProvider'] # Unknown type
      self
    end
  end

  # export interface DocumentLinkOptions {
  #     /**
  #      * Document links have a resolve provider as well.
  #      */
  #     resolveProvider?: boolean;
  # }
  class DocumentLinkOptions < LSPBase
    attr_accessor :resolveProvider # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[resolveProvider]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.resolveProvider = value['resolveProvider'] # Unknown type
      self
    end
  end

  # export interface ExecuteCommandOptions {
  #     /**
  #      * The commands to be executed on the server
  #      */
  #     commands: string[];
  # }
  class ExecuteCommandOptions < LSPBase
    attr_accessor :commands # type: string[]

    def from_h!(value)
      value = {} if value.nil?
      self.commands = value['commands'].map { |val| val } unless value['commands'].nil?
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

  # export interface TextDocumentSyncOptions {
  #     /**
  #      * Open and close notifications are sent to the server.
  #      */
  #     openClose?: boolean;
  #     /**
  #      * Change notifications are sent to the server. See TextDocumentSyncKind.None, TextDocumentSyncKind.Full
  #      * and TextDocumentSyncKind.Incremental.
  #      */
  #     change?: TextDocumentSyncKind;
  #     /**
  #      * Will save notifications are sent to the server.
  #      */
  #     willSave?: boolean;
  #     /**
  #      * Will save wait until requests are sent to the server.
  #      */
  #     willSaveWaitUntil?: boolean;
  #     /**
  #      * Save notifications are sent to the server.
  #      */
  #     save?: SaveOptions;
  # }
  class TextDocumentSyncOptions < LSPBase
    attr_accessor :openClose # type: boolean
    attr_accessor :change # type: TextDocumentSyncKind
    attr_accessor :willSave # type: boolean
    attr_accessor :willSaveWaitUntil # type: boolean
    attr_accessor :save # type: SaveOptions

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

  # export interface InitializeResult {
  #     /**
  #      * The capabilities the language server provides.
  #      */
  #     capabilities: ServerCapabilities;
  #     /**
  #      * Custom initialization results.
  #      */
  #     [custom: string]: any;
  # }
  class InitializeResult < LSPBase
    attr_accessor :capabilities # type: ServerCapabilities

    def from_h!(value)
      value = {} if value.nil?
      self.capabilities = value['capabilities'] # Unknown type
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
    attr_accessor :type # type: MessageType
    attr_accessor :message # type: string

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
    attr_accessor :type # type: MessageType
    attr_accessor :message # type: string
    attr_accessor :actions # type: MessageActionItem[]

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
    attr_accessor :type # type: MessageType
    attr_accessor :message # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.type = value['type'] # Unknown type
      self.message = value['message']
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
  #      * to the document. So if there are two content changes c1 and c2 for a document
  #      * in state S then c1 move the document to S' and c2 to S''.
  #      */
  #     contentChanges: TextDocumentContentChangeEvent[];
  # }
  class DidChangeTextDocumentParams < LSPBase
    attr_accessor :textDocument # type: VersionedTextDocumentIdentifier
    attr_accessor :contentChanges # type: TextDocumentContentChangeEvent[]

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
    attr_accessor :syncKind # type: TextDocumentSyncKind
    attr_accessor :documentSelector # type: DocumentSelector | null

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
    attr_accessor :textDocument # type: VersionedTextDocumentIdentifier
    attr_accessor :text # type: string

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
    attr_accessor :documentSelector # type: DocumentSelector | null
    attr_accessor :includeText # type: boolean

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
    attr_accessor :textDocument # type: TextDocumentIdentifier
    attr_accessor :reason # type: TextDocumentSaveReason

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = value['textDocument'] # Unknown type
      self.reason = value['reason'] # Unknown type
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
  #     uri: string;
  #     /**
  #      * The change type.
  #      */
  #     type: FileChangeType;
  # }
  class FileEvent < LSPBase
    attr_accessor :uri # type: string
    attr_accessor :type # type: FileChangeType

    def from_h!(value)
      value = {} if value.nil?
      self.uri = value['uri']
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
    attr_accessor :globPattern # type: string
    attr_accessor :kind # type: number

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

  # export interface PublishDiagnosticsParams {
  #     /**
  #      * The URI for which diagnostic information is reported.
  #      */
  #     uri: string;
  #     /**
  #      * An array of diagnostic information items.
  #      */
  #     diagnostics: Diagnostic[];
  # }
  class PublishDiagnosticsParams < LSPBase
    attr_accessor :uri # type: string
    attr_accessor :diagnostics # type: Diagnostic[]

    def from_h!(value)
      value = {} if value.nil?
      self.uri = value['uri']
      self.diagnostics = value['diagnostics'].map { |val| val } unless value['diagnostics'].nil? # Unknown array type
      self
    end
  end

  # export interface CompletionRegistrationOptions extends TextDocumentRegistrationOptions, CompletionOptions {
  # }
  class CompletionRegistrationOptions < LSPBase
    attr_accessor :documentSelector # type: DocumentSelector | null
    attr_accessor :triggerCharacters # type: string[]
    attr_accessor :resolveProvider # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[triggerCharacters resolveProvider]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.documentSelector = value['documentSelector'] # Unknown type
      self.triggerCharacters = value['triggerCharacters'].map { |val| val } unless value['triggerCharacters'].nil?
      self.resolveProvider = value['resolveProvider'] # Unknown type
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
    attr_accessor :triggerKind # type: CompletionTriggerKind
    attr_accessor :triggerCharacter # type: string

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

  # export interface CompletionParams extends TextDocumentPositionParams {
  #     /**
  #      * The completion context. This is only available it the client specifies
  #      * to send this using `ClientCapabilities.textDocument.completion.contextSupport === true`
  #      */
  #     context?: CompletionContext;
  # }
  class CompletionParams < LSPBase
    attr_accessor :context # type: CompletionContext
    attr_accessor :textDocument # type: TextDocumentIdentifier
    attr_accessor :position # type: Position

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[context]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.context = CompletionContext.new(value['context']) unless value['context'].nil?
      self.textDocument = value['textDocument'] # Unknown type
      self.position = value['position'] # Unknown type
      self
    end
  end

  # export interface SignatureHelpRegistrationOptions extends TextDocumentRegistrationOptions, SignatureHelpOptions {
  # }
  class SignatureHelpRegistrationOptions < LSPBase
    attr_accessor :documentSelector # type: DocumentSelector | null
    attr_accessor :triggerCharacters # type: string[]

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[triggerCharacters]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.documentSelector = value['documentSelector'] # Unknown type
      self.triggerCharacters = value['triggerCharacters'].map { |val| val } unless value['triggerCharacters'].nil?
      self
    end
  end

  # export interface ReferenceParams extends TextDocumentPositionParams {
  #     context: ReferenceContext;
  # }
  class ReferenceParams < LSPBase
    attr_accessor :context # type: ReferenceContext
    attr_accessor :textDocument # type: TextDocumentIdentifier
    attr_accessor :position # type: Position

    def from_h!(value)
      value = {} if value.nil?
      self.context = value['context'] # Unknown type
      self.textDocument = value['textDocument'] # Unknown type
      self.position = value['position'] # Unknown type
      self
    end
  end

  # export interface CodeActionParams {
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
    attr_accessor :textDocument # type: TextDocumentIdentifier
    attr_accessor :range # type: Range
    attr_accessor :context # type: CodeActionContext

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = value['textDocument'] # Unknown type
      self.range = value['range'] # Unknown type
      self.context = value['context'] # Unknown type
      self
    end
  end

  # export interface CodeActionRegistrationOptions extends TextDocumentRegistrationOptions, CodeActionOptions {
  # }
  class CodeActionRegistrationOptions < LSPBase
    attr_accessor :documentSelector # type: DocumentSelector | null
    attr_accessor :codeActionKinds # type: CodeActionKind[]

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[codeActionKinds]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.documentSelector = value['documentSelector'] # Unknown type
      self.codeActionKinds = value['codeActionKinds'].map { |val| val } unless value['codeActionKinds'].nil? # Unknown array type
      self
    end
  end

  # export interface CodeLensParams {
  #     /**
  #      * The document to request code lens for.
  #      */
  #     textDocument: TextDocumentIdentifier;
  # }
  class CodeLensParams < LSPBase
    attr_accessor :textDocument # type: TextDocumentIdentifier

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = value['textDocument'] # Unknown type
      self
    end
  end

  # export interface CodeLensRegistrationOptions extends TextDocumentRegistrationOptions, CodeLensOptions {
  # }
  class CodeLensRegistrationOptions < LSPBase
    attr_accessor :documentSelector # type: DocumentSelector | null
    attr_accessor :resolveProvider # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[resolveProvider]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.documentSelector = value['documentSelector'] # Unknown type
      self.resolveProvider = value['resolveProvider'] # Unknown type
      self
    end
  end

  # export interface DocumentFormattingParams {
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
    attr_accessor :textDocument # type: TextDocumentIdentifier
    attr_accessor :options # type: FormattingOptions

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = value['textDocument'] # Unknown type
      self.options = value['options'] # Unknown type
      self
    end
  end

  # export interface DocumentRangeFormattingParams {
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
    attr_accessor :textDocument # type: TextDocumentIdentifier
    attr_accessor :range # type: Range
    attr_accessor :options # type: FormattingOptions

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = value['textDocument'] # Unknown type
      self.range = value['range'] # Unknown type
      self.options = value['options'] # Unknown type
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
    attr_accessor :textDocument # type: TextDocumentIdentifier
    attr_accessor :position # type: Position
    attr_accessor :ch # type: string
    attr_accessor :options # type: FormattingOptions

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = value['textDocument'] # Unknown type
      self.position = value['position'] # Unknown type
      self.ch = value['ch']
      self.options = value['options'] # Unknown type
      self
    end
  end

  # export interface DocumentOnTypeFormattingRegistrationOptions extends TextDocumentRegistrationOptions, DocumentOnTypeFormattingOptions {
  # }
  class DocumentOnTypeFormattingRegistrationOptions < LSPBase
    attr_accessor :documentSelector # type: DocumentSelector | null
    attr_accessor :firstTriggerCharacter # type: string
    attr_accessor :moreTriggerCharacter # type: string[]

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

  # export interface RenameParams {
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
    attr_accessor :textDocument # type: TextDocumentIdentifier
    attr_accessor :position # type: Position
    attr_accessor :newName # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = value['textDocument'] # Unknown type
      self.position = value['position'] # Unknown type
      self.newName = value['newName']
      self
    end
  end

  # export interface RenameRegistrationOptions extends TextDocumentRegistrationOptions, RenameOptions {
  # }
  class RenameRegistrationOptions < LSPBase
    attr_accessor :documentSelector # type: DocumentSelector | null
    attr_accessor :prepareProvider # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[prepareProvider]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.documentSelector = value['documentSelector'] # Unknown type
      self.prepareProvider = value['prepareProvider'] # Unknown type
      self
    end
  end

  # export interface DocumentLinkParams {
  #     /**
  #      * The document to provide document links for.
  #      */
  #     textDocument: TextDocumentIdentifier;
  # }
  class DocumentLinkParams < LSPBase
    attr_accessor :textDocument # type: TextDocumentIdentifier

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = value['textDocument'] # Unknown type
      self
    end
  end

  # export interface DocumentLinkRegistrationOptions extends TextDocumentRegistrationOptions, DocumentLinkOptions {
  # }
  class DocumentLinkRegistrationOptions < LSPBase
    attr_accessor :documentSelector # type: DocumentSelector | null
    attr_accessor :resolveProvider # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[resolveProvider]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.documentSelector = value['documentSelector'] # Unknown type
      self.resolveProvider = value['resolveProvider'] # Unknown type
      self
    end
  end

  # export interface ExecuteCommandParams {
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
    attr_accessor :command # type: string
    attr_accessor :arguments # type: any[]

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[arguments]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.command = value['command']
      self.arguments = value['arguments'].map { |val| val } unless value['arguments'].nil?
      self
    end
  end

  # export interface ExecuteCommandRegistrationOptions extends ExecuteCommandOptions {
  # }
  class ExecuteCommandRegistrationOptions < LSPBase
    attr_accessor :commands # type: string[]

    def from_h!(value)
      value = {} if value.nil?
      self.commands = value['commands'].map { |val| val } unless value['commands'].nil?
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
    attr_accessor :label # type: string
    attr_accessor :edit # type: WorkspaceEdit

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
  #      * Depending on the client's failure handling strategy `failedChange` might
  #      * contain the index of the change that failed. This property is only available
  #      * if the client signals a `failureHandlingStrategy` in its client capabilities.
  #      */
  #     failedChange?: number;
  # }
  class ApplyWorkspaceEditResponse < LSPBase
    attr_accessor :applied # type: boolean
    attr_accessor :failedChange # type: number

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[failedChange]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.applied = value['applied'] # Unknown type
      self.failedChange = value['failedChange']
      self
    end
  end
end

# rubocop:enable Layout/EmptyLinesAroundClassBody
# rubocop:enable Lint/UselessAssignment
# rubocop:enable Style/AsciiComments
