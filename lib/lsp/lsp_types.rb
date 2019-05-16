# frozen_string_literal: true

# DO NOT MODIFY. This file is built automatically
# LSP Protocol: vscode-languageserver-types/lib/esm/main.d.ts

# rubocop:disable Layout/EmptyLinesAroundClassBody
# rubocop:disable Lint/UselessAssignment
# rubocop:disable Style/AsciiComments

module LSP
  # export interface Position {
  #     /**
  #      * Line position in a document (zero-based).
  #      * If a line number is greater than the number of lines in a document, it defaults back to the number of lines in the document.
  #      * If a line number is negative, it defaults to 0.
  #      */
  #     line: number;
  #     /**
  #      * Character offset on a line in a document (zero-based). Assuming that the line is
  #      * represented as a string, the `character` value represents the gap between the
  #      * `character` and `character + 1`.
  #      *
  #      * If the character value is greater than the line length it defaults back to the
  #      * line length.
  #      * If a line number is negative, it defaults to 0.
  #      */
  #     character: number;
  # }
  class Position < LSPBase
    attr_accessor :line # type: number
    attr_accessor :character # type: number

    def from_h!(value)
      value = {} if value.nil?
      self.line = value['line']
      self.character = value['character']
      self
    end
  end

  # export interface Range {
  #     /**
  #      * The range's start position
  #      */
  #     start: Position;
  #     /**
  #      * The range's end position.
  #      */
  #     end: Position;
  # }
  class Range < LSPBase
    attr_accessor :start # type: Position
    attr_accessor :end # type: Position

    def from_h!(value)
      value = {} if value.nil?
      self.start = Position.new(value['start']) unless value['start'].nil?
      self.end = Position.new(value['end']) unless value['end'].nil?
      self
    end
  end

  # export interface Location {
  #     uri: string;
  #     range: Range;
  # }
  class Location < LSPBase
    attr_accessor :uri # type: string
    attr_accessor :range # type: Range

    def from_h!(value)
      value = {} if value.nil?
      self.uri = value['uri']
      self.range = Range.new(value['range']) unless value['range'].nil?
      self
    end
  end

  # export interface LocationLink {
  #     /**
  #      * Span of the origin of this link.
  #      *
  #      * Used as the underlined span for mouse definition hover. Defaults to the word range at
  #      * the definition position.
  #      */
  #     originSelectionRange?: Range;
  #     /**
  #      * The target resource identifier of this link.
  #      */
  #     targetUri: string;
  #     /**
  #      * The full target range of this link. If the target for example is a symbol then target range is the
  #      * range enclosing this symbol not including leading/trailing whitespace but everything else
  #      * like comments. This information is typically used to highlight the range in the editor.
  #      */
  #     targetRange: Range;
  #     /**
  #      * The range that should be selected and revealed when this link is being followed, e.g the name of a function.
  #      * Must be contained by the the `targetRange`. See also `DocumentSymbol#range`
  #      */
  #     targetSelectionRange: Range;
  # }
  class LocationLink < LSPBase
    attr_accessor :originSelectionRange # type: Range
    attr_accessor :targetUri # type: string
    attr_accessor :targetRange # type: Range
    attr_accessor :targetSelectionRange # type: Range

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[originSelectionRange]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.originSelectionRange = Range.new(value['originSelectionRange']) unless value['originSelectionRange'].nil?
      self.targetUri = value['targetUri']
      self.targetRange = Range.new(value['targetRange']) unless value['targetRange'].nil?
      self.targetSelectionRange = Range.new(value['targetSelectionRange']) unless value['targetSelectionRange'].nil?
      self
    end
  end

  # export interface Color {
  #     /**
  #      * The red component of this color in the range [0-1].
  #      */
  #     readonly red: number;
  #     /**
  #      * The green component of this color in the range [0-1].
  #      */
  #     readonly green: number;
  #     /**
  #      * The blue component of this color in the range [0-1].
  #      */
  #     readonly blue: number;
  #     /**
  #      * The alpha component of this color in the range [0-1].
  #      */
  #     readonly alpha: number;
  # }
  class Color < LSPBase
    attr_accessor :red # type: number
    attr_accessor :green # type: number
    attr_accessor :blue # type: number
    attr_accessor :alpha # type: number

    def from_h!(value)
      value = {} if value.nil?
      self.red = value['red']
      self.green = value['green']
      self.blue = value['blue']
      self.alpha = value['alpha']
      self
    end
  end

  # export interface ColorInformation {
  #     /**
  #      * The range in the document where this color appers.
  #      */
  #     range: Range;
  #     /**
  #      * The actual color value for this color range.
  #      */
  #     color: Color;
  # }
  class ColorInformation < LSPBase
    attr_accessor :range # type: Range
    attr_accessor :color # type: Color

    def from_h!(value)
      value = {} if value.nil?
      self.range = Range.new(value['range']) unless value['range'].nil?
      self.color = Color.new(value['color']) unless value['color'].nil?
      self
    end
  end

  # export interface ColorPresentation {
  #     /**
  #      * The label of this color presentation. It will be shown on the color
  #      * picker header. By default this is also the text that is inserted when selecting
  #      * this color presentation.
  #      */
  #     label: string;
  #     /**
  #      * An [edit](#TextEdit) which is applied to a document when selecting
  #      * this presentation for the color.  When `falsy` the [label](#ColorPresentation.label)
  #      * is used.
  #      */
  #     textEdit?: TextEdit;
  #     /**
  #      * An optional array of additional [text edits](#TextEdit) that are applied when
  #      * selecting this color presentation. Edits must not overlap with the main [edit](#ColorPresentation.textEdit) nor with themselves.
  #      */
  #     additionalTextEdits?: TextEdit[];
  # }
  class ColorPresentation < LSPBase
    attr_accessor :label # type: string
    attr_accessor :textEdit # type: TextEdit
    attr_accessor :additionalTextEdits # type: TextEdit[]

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[textEdit additionalTextEdits]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.label = value['label']
      self.textEdit = TextEdit.new(value['textEdit']) unless value['textEdit'].nil?
      self.additionalTextEdits = to_typed_aray(value['additionalTextEdits'], TextEdit)
      self
    end
  end

  # export interface FoldingRange {
  #     /**
  #      * The zero-based line number from where the folded range starts.
  #      */
  #     startLine: number;
  #     /**
  #      * The zero-based character offset from where the folded range starts. If not defined, defaults to the length of the start line.
  #      */
  #     startCharacter?: number;
  #     /**
  #      * The zero-based line number where the folded range ends.
  #      */
  #     endLine: number;
  #     /**
  #      * The zero-based character offset before the folded range ends. If not defined, defaults to the length of the end line.
  #      */
  #     endCharacter?: number;
  #     /**
  #      * Describes the kind of the folding range such as `comment' or 'region'. The kind
  #      * is used to categorize folding ranges and used by commands like 'Fold all comments'. See
  #      * [FoldingRangeKind](#FoldingRangeKind) for an enumeration of standardized kinds.
  #      */
  #     kind?: string;
  # }
  class FoldingRange < LSPBase
    attr_accessor :startLine # type: number
    attr_accessor :startCharacter # type: number
    attr_accessor :endLine # type: number
    attr_accessor :endCharacter # type: number
    attr_accessor :kind # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[startCharacter endCharacter kind]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.startLine = value['startLine']
      self.startCharacter = value['startCharacter']
      self.endLine = value['endLine']
      self.endCharacter = value['endCharacter']
      self.kind = value['kind']
      self
    end
  end

  # export interface DiagnosticRelatedInformation {
  #     /**
  #      * The location of this related diagnostic information.
  #      */
  #     location: Location;
  #     /**
  #      * The message of this related diagnostic information.
  #      */
  #     message: string;
  # }
  class DiagnosticRelatedInformation < LSPBase
    attr_accessor :location # type: Location
    attr_accessor :message # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.location = Location.new(value['location']) unless value['location'].nil?
      self.message = value['message']
      self
    end
  end

  # export interface Diagnostic {
  #     /**
  #      * The range at which the message applies
  #      */
  #     range: Range;
  #     /**
  #      * The diagnostic's severity. Can be omitted. If omitted it is up to the
  #      * client to interpret diagnostics as error, warning, info or hint.
  #      */
  #     severity?: DiagnosticSeverity;
  #     /**
  #      * The diagnostic's code, which usually appear in the user interface.
  #      */
  #     code?: number | string;
  #     /**
  #      * A human-readable string describing the source of this
  #      * diagnostic, e.g. 'typescript' or 'super lint'. It usually
  #      * appears in the user interface.
  #      */
  #     source?: string;
  #     /**
  #      * The diagnostic's message. It usually appears in the user interface
  #      */
  #     message: string;
  #     /**
  #      * An array of related diagnostic information, e.g. when symbol-names within
  #      * a scope collide all definitions can be marked via this property.
  #      */
  #     relatedInformation?: DiagnosticRelatedInformation[];
  # }
  class Diagnostic < LSPBase
    attr_accessor :range # type: Range
    attr_accessor :severity # type: DiagnosticSeverity
    attr_accessor :code # type: number | string
    attr_accessor :source # type: string
    attr_accessor :message # type: string
    attr_accessor :relatedInformation # type: DiagnosticRelatedInformation[]

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[severity code source relatedInformation]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.range = Range.new(value['range']) unless value['range'].nil?
      self.severity = value['severity'] # Unknown type
      self.code = value['code'] # Unknown type
      self.source = value['source']
      self.message = value['message']
      self.relatedInformation = to_typed_aray(value['relatedInformation'], DiagnosticRelatedInformation)
      self
    end
  end

  # export interface Command {
  #     /**
  #      * Title of the command, like `save`.
  #      */
  #     title: string;
  #     /**
  #      * The identifier of the actual command handler.
  #      */
  #     command: string;
  #     /**
  #      * Arguments that the command handler should be
  #      * invoked with.
  #      */
  #     arguments?: any[];
  # }
  class Command < LSPBase
    attr_accessor :title # type: string
    attr_accessor :command # type: string
    attr_accessor :arguments # type: any[]

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[arguments]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.title = value['title']
      self.command = value['command']
      self.arguments = value['arguments'].map { |val| val } unless value['arguments'].nil?
      self
    end
  end

  # export interface TextEdit {
  #     /**
  #      * The range of the text document to be manipulated. To insert
  #      * text into a document create a range where start === end.
  #      */
  #     range: Range;
  #     /**
  #      * The string to be inserted. For delete operations use an
  #      * empty string.
  #      */
  #     newText: string;
  # }
  class TextEdit < LSPBase
    attr_accessor :range # type: Range
    attr_accessor :newText # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.range = Range.new(value['range']) unless value['range'].nil?
      self.newText = value['newText']
      self
    end
  end

  # export interface TextDocumentEdit {
  #     /**
  #      * The text document to change.
  #      */
  #     textDocument: VersionedTextDocumentIdentifier;
  #     /**
  #      * The edits to be applied.
  #      */
  #     edits: TextEdit[];
  # }
  class TextDocumentEdit < LSPBase
    attr_accessor :textDocument # type: VersionedTextDocumentIdentifier
    attr_accessor :edits # type: TextEdit[]

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = VersionedTextDocumentIdentifier.new(value['textDocument']) unless value['textDocument'].nil?
      self.edits = to_typed_aray(value['edits'], TextEdit)
      self
    end
  end

  # interface ResourceOperation {
  #     kind: string;
  # }
  class ResourceOperation < LSPBase
    attr_accessor :kind # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.kind = value['kind']
      self
    end
  end

  # export interface CreateFileOptions {
  #     /**
  #      * Overwrite existing file. Overwrite wins over `ignoreIfExists`
  #      */
  #     overwrite?: boolean;
  #     /**
  #      * Ignore if exists.
  #      */
  #     ignoreIfExists?: boolean;
  # }
  class CreateFileOptions < LSPBase
    attr_accessor :overwrite # type: boolean
    attr_accessor :ignoreIfExists # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[overwrite ignoreIfExists]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.overwrite = value['overwrite'] # Unknown type
      self.ignoreIfExists = value['ignoreIfExists'] # Unknown type
      self
    end
  end

  # export interface CreateFile extends ResourceOperation {
  #     /**
  #      * A create
  #      */
  #     kind: 'create';
  #     /**
  #      * The resource to create.
  #      */
  #     uri: string;
  #     /**
  #      * Additional options
  #      */
  #     options?: CreateFileOptions;
  # }
  class CreateFile < LSPBase
    attr_accessor :kind # type: string with value 'create'
    attr_accessor :uri # type: string
    attr_accessor :options # type: CreateFileOptions

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[options]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.kind = value['kind'] # Unknown type
      self.uri = value['uri']
      self.options = CreateFileOptions.new(value['options']) unless value['options'].nil?
      self
    end
  end

  # export interface RenameFileOptions {
  #     /**
  #      * Overwrite target if existing. Overwrite wins over `ignoreIfExists`
  #      */
  #     overwrite?: boolean;
  #     /**
  #      * Ignores if target exists.
  #      */
  #     ignoreIfExists?: boolean;
  # }
  class RenameFileOptions < LSPBase
    attr_accessor :overwrite # type: boolean
    attr_accessor :ignoreIfExists # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[overwrite ignoreIfExists]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.overwrite = value['overwrite'] # Unknown type
      self.ignoreIfExists = value['ignoreIfExists'] # Unknown type
      self
    end
  end

  # export interface RenameFile extends ResourceOperation {
  #     /**
  #      * A rename
  #      */
  #     kind: 'rename';
  #     /**
  #      * The old (existing) location.
  #      */
  #     oldUri: string;
  #     /**
  #      * The new location.
  #      */
  #     newUri: string;
  #     /**
  #      * Rename options.
  #      */
  #     options?: RenameFileOptions;
  # }
  class RenameFile < LSPBase
    attr_accessor :kind # type: string with value 'rename'
    attr_accessor :oldUri # type: string
    attr_accessor :newUri # type: string
    attr_accessor :options # type: RenameFileOptions

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[options]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.kind = value['kind'] # Unknown type
      self.oldUri = value['oldUri']
      self.newUri = value['newUri']
      self.options = RenameFileOptions.new(value['options']) unless value['options'].nil?
      self
    end
  end

  # export interface DeleteFileOptions {
  #     /**
  #      * Delete the content recursively if a folder is denoted.
  #      */
  #     recursive?: boolean;
  #     /**
  #      * Ignore the operation if the file doesn't exist.
  #      */
  #     ignoreIfNotExists?: boolean;
  # }
  class DeleteFileOptions < LSPBase
    attr_accessor :recursive # type: boolean
    attr_accessor :ignoreIfNotExists # type: boolean

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[recursive ignoreIfNotExists]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.recursive = value['recursive'] # Unknown type
      self.ignoreIfNotExists = value['ignoreIfNotExists'] # Unknown type
      self
    end
  end

  # export interface DeleteFile extends ResourceOperation {
  #     /**
  #      * A delete
  #      */
  #     kind: 'delete';
  #     /**
  #      * The file to delete.
  #      */
  #     uri: string;
  #     /**
  #      * Delete options.
  #      */
  #     options?: DeleteFileOptions;
  # }
  class DeleteFile < LSPBase
    attr_accessor :kind # type: string with value 'delete'
    attr_accessor :uri # type: string
    attr_accessor :options # type: DeleteFileOptions

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[options]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.kind = value['kind'] # Unknown type
      self.uri = value['uri']
      self.options = DeleteFileOptions.new(value['options']) unless value['options'].nil?
      self
    end
  end

  # export interface WorkspaceEdit {
  #     /**
  #      * Holds changes to existing resources.
  #      */
  #     changes?: {
  #         [uri: string]: TextEdit[];
  #     };
  #     /**
  #      * Depending on the client capability `workspace.workspaceEdit.resourceOperations` document changes
  #      * are either an array of `TextDocumentEdit`s to express changes to n different text documents
  #      * where each text document edit addresses a specific version of a text document. Or it can contain
  #      * above `TextDocumentEdit`s mixed with create, rename and delete file / folder operations.
  #      *
  #      * Whether a client supports versioned document edits is expressed via
  #      * `workspace.workspaceEdit.documentChanges` client capability.
  #      *
  #      * If a client neither supports `documentChanges` nor `workspace.workspaceEdit.resourceOperations` then
  #      * only plain `TextEdit`s using the `changes` property are supported.
  #      */
  #     documentChanges?: (TextDocumentEdit | CreateFile | RenameFile | DeleteFile)[];
  # }
  class WorkspaceEdit < LSPBase
    attr_accessor :changes # type: {
    #        [uri: string]: TextEdit[];
    #    }
    attr_accessor :documentChanges # type: (TextDocumentEdit | CreateFile | RenameFile | DeleteFile)[]

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[changes documentChanges]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.changes = value['changes'] # Unknown type
      self.documentChanges = value['documentChanges'] # Unknown type
      self
    end
  end

  # export declare class WorkspaceChange {
  #     private _workspaceEdit;
  #     private _textEditChanges;
  #     constructor(workspaceEdit?: WorkspaceEdit);
  #     /**
  #      * Returns the underlying [WorkspaceEdit](#WorkspaceEdit) literal
  #      * use to be returned from a workspace edit operation like rename.
  #      */
  #     readonly edit: WorkspaceEdit;
  #     /**
  #      * Returns the [TextEditChange](#TextEditChange) to manage text edits
  #      * for resources.
  #      */
  #     getTextEditChange(textDocument: VersionedTextDocumentIdentifier): TextEditChange;
  #     getTextEditChange(uri: string): TextEditChange;
  #     createFile(uri: string, options?: CreateFileOptions): void;
  #     renameFile(oldUri: string, newUri: string, options?: RenameFileOptions): void;
  #     deleteFile(uri: string, options?: DeleteFileOptions): void;
  #     private checkDocumentChanges;
  # }
  class WorkspaceChange < LSPBase
    attr_accessor :edit # type: WorkspaceEdit

    def from_h!(value)
      value = {} if value.nil?
      self.edit = WorkspaceEdit.new(value['edit']) unless value['edit'].nil?
      self
    end
  end

  # export interface TextDocumentIdentifier {
  #     /**
  #      * The text document's uri.
  #      */
  #     uri: string;
  # }
  class TextDocumentIdentifier < LSPBase
    attr_accessor :uri # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.uri = value['uri']
      self
    end
  end

  # export interface VersionedTextDocumentIdentifier extends TextDocumentIdentifier {
  #     /**
  #      * The version number of this document. If a versioned text document identifier
  #      * is sent from the server to the client and the file is not open in the editor
  #      * (the server has not received an open notification before) the server can send
  #      * `null` to indicate that the version is unknown and the content on disk is the
  #      * truth (as speced with document content ownership).
  #      */
  #     version: number | null;
  # }
  class VersionedTextDocumentIdentifier < LSPBase
    attr_accessor :version # type: number | null
    attr_accessor :uri # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.version = value['version'] # Unknown type
      self.uri = value['uri']
      self
    end
  end

  # export interface TextDocumentItem {
  #     /**
  #      * The text document's uri.
  #      */
  #     uri: string;
  #     /**
  #      * The text document's language identifier
  #      */
  #     languageId: string;
  #     /**
  #      * The version number of this document (it will increase after each
  #      * change, including undo/redo).
  #      */
  #     version: number;
  #     /**
  #      * The content of the opened text document.
  #      */
  #     text: string;
  # }
  class TextDocumentItem < LSPBase
    attr_accessor :uri # type: string
    attr_accessor :languageId # type: string
    attr_accessor :version # type: number
    attr_accessor :text # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.uri = value['uri']
      self.languageId = value['languageId']
      self.version = value['version']
      self.text = value['text']
      self
    end
  end

  # export interface MarkupContent {
  #     /**
  #      * The type of the Markup
  #      */
  #     kind: MarkupKind;
  #     /**
  #      * The content itself
  #      */
  #     value: string;
  # }
  class MarkupContent < LSPBase
    attr_accessor :kind # type: MarkupKind
    attr_accessor :value # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.kind = value['kind'] # Unknown type
      self.value = value['value']
      self
    end
  end

  # export interface CompletionItem {
  #     /**
  #      * The label of this completion item. By default
  #      * also the text that is inserted when selecting
  #      * this completion.
  #      */
  #     label: string;
  #     /**
  #      * The kind of this completion item. Based of the kind
  #      * an icon is chosen by the editor.
  #      */
  #     kind?: CompletionItemKind;
  #     /**
  #      * A human-readable string with additional information
  #      * about this item, like type or symbol information.
  #      */
  #     detail?: string;
  #     /**
  #      * A human-readable string that represents a doc-comment.
  #      */
  #     documentation?: string | MarkupContent;
  #     /**
  #      * Indicates if this item is deprecated.
  #      */
  #     deprecated?: boolean;
  #     /**
  #      * Select this item when showing.
  #      *
  #      * *Note* that only one completion item can be selected and that the
  #      * tool / client decides which item that is. The rule is that the *first*
  #      * item of those that match best is selected.
  #      */
  #     preselect?: boolean;
  #     /**
  #      * A string that should be used when comparing this item
  #      * with other items. When `falsy` the [label](#CompletionItem.label)
  #      * is used.
  #      */
  #     sortText?: string;
  #     /**
  #      * A string that should be used when filtering a set of
  #      * completion items. When `falsy` the [label](#CompletionItem.label)
  #      * is used.
  #      */
  #     filterText?: string;
  #     /**
  #      * A string that should be inserted into a document when selecting
  #      * this completion. When `falsy` the [label](#CompletionItem.label)
  #      * is used.
  #      *
  #      * The `insertText` is subject to interpretation by the client side.
  #      * Some tools might not take the string literally. For example
  #      * VS Code when code complete is requested in this example `con<cursor position>`
  #      * and a completion item with an `insertText` of `console` is provided it
  #      * will only insert `sole`. Therefore it is recommended to use `textEdit` instead
  #      * since it avoids additional client side interpretation.
  #      *
  #      * @deprecated Use textEdit instead.
  #      */
  #     insertText?: string;
  #     /**
  #      * The format of the insert text. The format applies to both the `insertText` property
  #      * and the `newText` property of a provided `textEdit`.
  #      */
  #     insertTextFormat?: InsertTextFormat;
  #     /**
  #      * An [edit](#TextEdit) which is applied to a document when selecting
  #      * this completion. When an edit is provided the value of
  #      * [insertText](#CompletionItem.insertText) is ignored.
  #      *
  #      * *Note:* The text edit's range must be a [single line] and it must contain the position
  #      * at which completion has been requested.
  #      */
  #     textEdit?: TextEdit;
  #     /**
  #      * An optional array of additional [text edits](#TextEdit) that are applied when
  #      * selecting this completion. Edits must not overlap (including the same insert position)
  #      * with the main [edit](#CompletionItem.textEdit) nor with themselves.
  #      *
  #      * Additional text edits should be used to change text unrelated to the current cursor position
  #      * (for example adding an import statement at the top of the file if the completion item will
  #      * insert an unqualified type).
  #      */
  #     additionalTextEdits?: TextEdit[];
  #     /**
  #      * An optional set of characters that when pressed while this completion is active will accept it first and
  #      * then type that character. *Note* that all commit characters should have `length=1` and that superfluous
  #      * characters will be ignored.
  #      */
  #     commitCharacters?: string[];
  #     /**
  #      * An optional [command](#Command) that is executed *after* inserting this completion. *Note* that
  #      * additional modifications to the current document should be described with the
  #      * [additionalTextEdits](#CompletionItem.additionalTextEdits)-property.
  #      */
  #     command?: Command;
  #     /**
  #      * An data entry field that is preserved on a completion item between
  #      * a [CompletionRequest](#CompletionRequest) and a [CompletionResolveRequest]
  #      * (#CompletionResolveRequest)
  #      */
  #     data?: any;
  # }
  class CompletionItem < LSPBase
    attr_accessor :label # type: string
    attr_accessor :kind # type: CompletionItemKind
    attr_accessor :detail # type: string
    attr_accessor :documentation # type: string | MarkupContent
    attr_accessor :deprecated # type: boolean
    attr_accessor :preselect # type: boolean
    attr_accessor :sortText # type: string
    attr_accessor :filterText # type: string
    attr_accessor :insertText # type: string
    attr_accessor :insertTextFormat # type: InsertTextFormat
    attr_accessor :textEdit # type: TextEdit
    attr_accessor :additionalTextEdits # type: TextEdit[]
    attr_accessor :commitCharacters # type: string[]
    attr_accessor :command # type: Command
    attr_accessor :data # type: any

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[kind detail documentation deprecated preselect sortText filterText insertText insertTextFormat textEdit additionalTextEdits commitCharacters command data]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.label = value['label']
      self.kind = value['kind'] # Unknown type
      self.detail = value['detail']
      self.documentation = value['documentation'] # Unknown type
      self.deprecated = value['deprecated'] # Unknown type
      self.preselect = value['preselect'] # Unknown type
      self.sortText = value['sortText']
      self.filterText = value['filterText']
      self.insertText = value['insertText']
      self.insertTextFormat = value['insertTextFormat'] # Unknown type
      self.textEdit = TextEdit.new(value['textEdit']) unless value['textEdit'].nil?
      self.additionalTextEdits = to_typed_aray(value['additionalTextEdits'], TextEdit)
      self.commitCharacters = value['commitCharacters'].map { |val| val } unless value['commitCharacters'].nil?
      self.command = Command.new(value['command']) unless value['command'].nil?
      self.data = value['data']
      self
    end
  end

  # export interface CompletionList {
  #     /**
  #      * This list it not complete. Further typing results in recomputing this list.
  #      */
  #     isIncomplete: boolean;
  #     /**
  #      * The completion items.
  #      */
  #     items: CompletionItem[];
  # }
  class CompletionList < LSPBase
    attr_accessor :isIncomplete # type: boolean
    attr_accessor :items # type: CompletionItem[]

    def from_h!(value)
      value = {} if value.nil?
      self.isIncomplete = value['isIncomplete'] # Unknown type
      self.items = to_typed_aray(value['items'], CompletionItem)
      self
    end
  end

  # export interface Hover {
  #     /**
  #      * The hover's content
  #      */
  #     contents: MarkupContent | MarkedString | MarkedString[];
  #     /**
  #      * An optional range
  #      */
  #     range?: Range;
  # }
  class Hover < LSPBase
    attr_accessor :contents # type: MarkupContent | MarkedString | MarkedString[]
    attr_accessor :range # type: Range

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[range]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.contents = value['contents'] # Unknown type
      self.range = Range.new(value['range']) unless value['range'].nil?
      self
    end
  end

  # export interface ParameterInformation {
  #     /**
  #      * The label of this parameter information.
  #      *
  #      * Either a string or inclusive start and exclusive end offsets within its containing
  #      * [signature label](#SignatureInformation.label). *Note*: A label of type string must be
  #      * a substring of its containing signature information's [label](#SignatureInformation.label).
  #      */
  #     label: string | [number, number];
  #     /**
  #      * The human-readable doc-comment of this signature. Will be shown
  #      * in the UI but can be omitted.
  #      */
  #     documentation?: string | MarkupContent;
  # }
  class ParameterInformation < LSPBase
    attr_accessor :label # type: string | [number, number]
    attr_accessor :documentation # type: string | MarkupContent

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[documentation]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.label = value['label'] # Unknown type
      self.documentation = value['documentation'] # Unknown type
      self
    end
  end

  # export interface SignatureInformation {
  #     /**
  #      * The label of this signature. Will be shown in
  #      * the UI.
  #      */
  #     label: string;
  #     /**
  #      * The human-readable doc-comment of this signature. Will be shown
  #      * in the UI but can be omitted.
  #      */
  #     documentation?: string | MarkupContent;
  #     /**
  #      * The parameters of this signature.
  #      */
  #     parameters?: ParameterInformation[];
  # }
  class SignatureInformation < LSPBase
    attr_accessor :label # type: string
    attr_accessor :documentation # type: string | MarkupContent
    attr_accessor :parameters # type: ParameterInformation[]

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[documentation parameters]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.label = value['label']
      self.documentation = value['documentation'] # Unknown type
      self.parameters = to_typed_aray(value['parameters'], ParameterInformation)
      self
    end
  end

  # export interface SignatureHelp {
  #     /**
  #      * One or more signatures.
  #      */
  #     signatures: SignatureInformation[];
  #     /**
  #      * The active signature. Set to `null` if no
  #      * signatures exist.
  #      */
  #     activeSignature: number | null;
  #     /**
  #      * The active parameter of the active signature. Set to `null`
  #      * if the active signature has no parameters.
  #      */
  #     activeParameter: number | null;
  # }
  class SignatureHelp < LSPBase
    attr_accessor :signatures # type: SignatureInformation[]
    attr_accessor :activeSignature # type: number | null
    attr_accessor :activeParameter # type: number | null

    def from_h!(value)
      value = {} if value.nil?
      self.signatures = to_typed_aray(value['signatures'], SignatureInformation)
      self.activeSignature = value['activeSignature'] # Unknown type
      self.activeParameter = value['activeParameter'] # Unknown type
      self
    end
  end

  # export interface ReferenceContext {
  #     /**
  #      * Include the declaration of the current symbol.
  #      */
  #     includeDeclaration: boolean;
  # }
  class ReferenceContext < LSPBase
    attr_accessor :includeDeclaration # type: boolean

    def from_h!(value)
      value = {} if value.nil?
      self.includeDeclaration = value['includeDeclaration'] # Unknown type
      self
    end
  end

  # export interface DocumentHighlight {
  #     /**
  #      * The range this highlight applies to.
  #      */
  #     range: Range;
  #     /**
  #      * The highlight kind, default is [text](#DocumentHighlightKind.Text).
  #      */
  #     kind?: DocumentHighlightKind;
  # }
  class DocumentHighlight < LSPBase
    attr_accessor :range # type: Range
    attr_accessor :kind # type: DocumentHighlightKind

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[kind]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.range = Range.new(value['range']) unless value['range'].nil?
      self.kind = value['kind'] # Unknown type
      self
    end
  end

  # export interface SymbolInformation {
  #     /**
  #      * The name of this symbol.
  #      */
  #     name: string;
  #     /**
  #      * The kind of this symbol.
  #      */
  #     kind: SymbolKind;
  #     /**
  #      * Indicates if this symbol is deprecated.
  #      */
  #     deprecated?: boolean;
  #     /**
  #      * The location of this symbol. The location's range is used by a tool
  #      * to reveal the location in the editor. If the symbol is selected in the
  #      * tool the range's start information is used to position the cursor. So
  #      * the range usually spans more than the actual symbol's name and does
  #      * normally include thinks like visibility modifiers.
  #      *
  #      * The range doesn't have to denote a node range in the sense of a abstract
  #      * syntax tree. It can therefore not be used to re-construct a hierarchy of
  #      * the symbols.
  #      */
  #     location: Location;
  #     /**
  #      * The name of the symbol containing this symbol. This information is for
  #      * user interface purposes (e.g. to render a qualifier in the user interface
  #      * if necessary). It can't be used to re-infer a hierarchy for the document
  #      * symbols.
  #      */
  #     containerName?: string;
  # }
  class SymbolInformation < LSPBase
    attr_accessor :name # type: string
    attr_accessor :kind # type: SymbolKind
    attr_accessor :deprecated # type: boolean
    attr_accessor :location # type: Location
    attr_accessor :containerName # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[deprecated containerName]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.name = value['name']
      self.kind = value['kind'] # Unknown type
      self.deprecated = value['deprecated'] # Unknown type
      self.location = Location.new(value['location']) unless value['location'].nil?
      self.containerName = value['containerName']
      self
    end
  end

  # export declare class DocumentSymbol {
  #     /**
  #      * The name of this symbol.
  #      */
  #     name: string;
  #     /**
  #      * More detail for this symbol, e.g the signature of a function.
  #      */
  #     detail?: string;
  #     /**
  #      * The kind of this symbol.
  #      */
  #     kind: SymbolKind;
  #     /**
  #      * Indicates if this symbol is deprecated.
  #      */
  #     deprecated?: boolean;
  #     /**
  #      * The range enclosing this symbol not including leading/trailing whitespace but everything else
  #      * like comments. This information is typically used to determine if the the clients cursor is
  #      * inside the symbol to reveal in the symbol in the UI.
  #      */
  #     range: Range;
  #     /**
  #      * The range that should be selected and revealed when this symbol is being picked, e.g the name of a function.
  #      * Must be contained by the the `range`.
  #      */
  #     selectionRange: Range;
  #     /**
  #      * Children of this symbol, e.g. properties of a class.
  #      */
  #     children?: DocumentSymbol[];
  # }
  class DocumentSymbol < LSPBase
    attr_accessor :name # type: string
    attr_accessor :detail # type: string
    attr_accessor :kind # type: SymbolKind
    attr_accessor :deprecated # type: boolean
    attr_accessor :range # type: Range
    attr_accessor :selectionRange # type: Range
    attr_accessor :children # type: DocumentSymbol[]

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[detail deprecated children]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.name = value['name']
      self.detail = value['detail']
      self.kind = value['kind'] # Unknown type
      self.deprecated = value['deprecated'] # Unknown type
      self.range = Range.new(value['range']) unless value['range'].nil?
      self.selectionRange = Range.new(value['selectionRange']) unless value['selectionRange'].nil?
      self.children = to_typed_aray(value['children'], DocumentSymbol)
      self
    end
  end

  # export interface DocumentSymbolParams {
  #     /**
  #      * The text document.
  #      */
  #     textDocument: TextDocumentIdentifier;
  # }
  class DocumentSymbolParams < LSPBase
    attr_accessor :textDocument # type: TextDocumentIdentifier

    def from_h!(value)
      value = {} if value.nil?
      self.textDocument = TextDocumentIdentifier.new(value['textDocument']) unless value['textDocument'].nil?
      self
    end
  end

  # export interface WorkspaceSymbolParams {
  #     /**
  #      * A non-empty query string
  #      */
  #     query: string;
  # }
  class WorkspaceSymbolParams < LSPBase
    attr_accessor :query # type: string

    def from_h!(value)
      value = {} if value.nil?
      self.query = value['query']
      self
    end
  end

  # export interface CodeActionContext {
  #     /**
  #      * An array of diagnostics known on the client side overlapping the range provided to the
  #      * `textDocument/codeAction` request. They are provied so that the server knows which
  #      * errors are currently presented to the user for the given range. There is no guarantee
  #      * that these accurately reflect the error state of the resource. The primary parameter
  #      * to compute code actions is the provided range.
  #      */
  #     diagnostics: Diagnostic[];
  #     /**
  #      * Requested kind of actions to return.
  #      *
  #      * Actions not of this kind are filtered out by the client before being shown. So servers
  #      * can omit computing them.
  #      */
  #     only?: CodeActionKind[];
  # }
  class CodeActionContext < LSPBase
    attr_accessor :diagnostics # type: Diagnostic[]
    attr_accessor :only # type: CodeActionKind[]

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[only]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.diagnostics = to_typed_aray(value['diagnostics'], Diagnostic)
      self.only = value['only'].map { |val| val } unless value['only'].nil? # Unknown array type
      self
    end
  end

  # export interface CodeAction {
  #     /**
  #      * A short, human-readable, title for this code action.
  #      */
  #     title: string;
  #     /**
  #      * The kind of the code action.
  #      *
  #      * Used to filter code actions.
  #      */
  #     kind?: CodeActionKind;
  #     /**
  #      * The diagnostics that this code action resolves.
  #      */
  #     diagnostics?: Diagnostic[];
  #     /**
  #      * The workspace edit this code action performs.
  #      */
  #     edit?: WorkspaceEdit;
  #     /**
  #      * A command this code action executes. If a code action
  #      * provides a edit and a command, first the edit is
  #      * executed and then the command.
  #      */
  #     command?: Command;
  # }
  class CodeAction < LSPBase
    attr_accessor :title # type: string
    attr_accessor :kind # type: CodeActionKind
    attr_accessor :diagnostics # type: Diagnostic[]
    attr_accessor :edit # type: WorkspaceEdit
    attr_accessor :command # type: Command

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[kind diagnostics edit command]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.title = value['title']
      self.kind = value['kind'] # Unknown type
      self.diagnostics = to_typed_aray(value['diagnostics'], Diagnostic)
      self.edit = WorkspaceEdit.new(value['edit']) unless value['edit'].nil?
      self.command = Command.new(value['command']) unless value['command'].nil?
      self
    end
  end

  # export interface CodeLens {
  #     /**
  #      * The range in which this code lens is valid. Should only span a single line.
  #      */
  #     range: Range;
  #     /**
  #      * The command this code lens represents.
  #      */
  #     command?: Command;
  #     /**
  #      * An data entry field that is preserved on a code lens item between
  #      * a [CodeLensRequest](#CodeLensRequest) and a [CodeLensResolveRequest]
  #      * (#CodeLensResolveRequest)
  #      */
  #     data?: any;
  # }
  class CodeLens < LSPBase
    attr_accessor :range # type: Range
    attr_accessor :command # type: Command
    attr_accessor :data # type: any

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[command data]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.range = Range.new(value['range']) unless value['range'].nil?
      self.command = Command.new(value['command']) unless value['command'].nil?
      self.data = value['data']
      self
    end
  end

  # export interface FormattingOptions {
  #     /**
  #      * Size of a tab in spaces.
  #      */
  #     tabSize: number;
  #     /**
  #      * Prefer spaces over tabs.
  #      */
  #     insertSpaces: boolean;
  #     /**
  #      * Signature for further properties.
  #      */
  #     [key: string]: boolean | number | string;
  # }
  class FormattingOptions < LSPBase
    attr_accessor :tabSize # type: number
    attr_accessor :insertSpaces # type: boolean

    def from_h!(value)
      value = {} if value.nil?
      self.tabSize = value['tabSize']
      self.insertSpaces = value['insertSpaces'] # Unknown type
      self
    end
  end

  # export declare class DocumentLink {
  #     /**
  #      * The range this link applies to.
  #      */
  #     range: Range;
  #     /**
  #      * The uri this link points to.
  #      */
  #     target?: string;
  #     /**
  #      * A data entry field that is preserved on a document link between a
  #      * DocumentLinkRequest and a DocumentLinkResolveRequest.
  #      */
  #     data?: any;
  # }
  class DocumentLink < LSPBase
    attr_accessor :range # type: Range
    attr_accessor :target # type: string
    attr_accessor :data # type: any

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[target data]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.range = Range.new(value['range']) unless value['range'].nil?
      self.target = value['target']
      self.data = value['data']
      self
    end
  end

  # export interface TextDocument {
  #     /**
  #      * The associated URI for this document. Most documents have the __file__-scheme, indicating that they
  #      * represent files on disk. However, some documents may have other schemes indicating that they are not
  #      * available on disk.
  #      *
  #      * @readonly
  #      */
  #     readonly uri: string;
  #     /**
  #      * The identifier of the language associated with this document.
  #      *
  #      * @readonly
  #      */
  #     readonly languageId: string;
  #     /**
  #      * The version number of this document (it will increase after each
  #      * change, including undo/redo).
  #      *
  #      * @readonly
  #      */
  #     readonly version: number;
  #     /**
  #      * Get the text of this document. A substring can be retrieved by
  #      * providing a range.
  #      *
  #      * @param range (optional) An range within the document to return.
  #      * If no range is passed, the full content is returned.
  #      * Invalid range positions are adjusted as described in [Position.line](#Position.line)
  #      * and [Position.character](#Position.character).
  #      * If the start range position is greater than the end range position,
  #      * then the effect of getText is as if the two positions were swapped.
  #
  #      * @return The text of this document or a substring of the text if a
  #      *         range is provided.
  #      */
  #     getText(range?: Range): string;
  #     /**
  #      * Converts a zero-based offset to a position.
  #      *
  #      * @param offset A zero-based offset.
  #      * @return A valid [position](#Position).
  #      */
  #     positionAt(offset: number): Position;
  #     /**
  #      * Converts the position to a zero-based offset.
  #      * Invalid positions are adjusted as described in [Position.line](#Position.line)
  #      * and [Position.character](#Position.character).
  #      *
  #      * @param position A position.
  #      * @return A valid zero-based offset.
  #      */
  #     offsetAt(position: Position): number;
  #     /**
  #      * The number of lines in this document.
  #      *
  #      * @readonly
  #      */
  #     readonly lineCount: number;
  # }
  class TextDocument < LSPBase
    attr_accessor :uri # type: string
    attr_accessor :languageId # type: string
    attr_accessor :version # type: number
    attr_accessor :lineCount # type: number

    def from_h!(value)
      value = {} if value.nil?
      self.uri = value['uri']
      self.languageId = value['languageId']
      self.version = value['version']
      self.lineCount = value['lineCount']
      self
    end
  end

  # export interface TextDocumentChangeEvent {
  #     /**
  #      * The document that has changed.
  #      */
  #     document: TextDocument;
  # }
  class TextDocumentChangeEvent < LSPBase
    attr_accessor :document # type: TextDocument

    def from_h!(value)
      value = {} if value.nil?
      self.document = TextDocument.new(value['document']) unless value['document'].nil?
      self
    end
  end

  # export interface TextDocumentWillSaveEvent {
  #     /**
  #      * The document that will be saved
  #      */
  #     document: TextDocument;
  #     /**
  #      * The reason why save was triggered.
  #      */
  #     reason: TextDocumentSaveReason;
  # }
  class TextDocumentWillSaveEvent < LSPBase
    attr_accessor :document # type: TextDocument
    attr_accessor :reason # type: TextDocumentSaveReason

    def from_h!(value)
      value = {} if value.nil?
      self.document = TextDocument.new(value['document']) unless value['document'].nil?
      self.reason = value['reason'] # Unknown type
      self
    end
  end

  # export interface TextDocumentContentChangeEvent {
  #     /**
  #      * The range of the document that changed.
  #      */
  #     range?: Range;
  #     /**
  #      * The length of the range that got replaced.
  #      */
  #     rangeLength?: number;
  #     /**
  #      * The new text of the document.
  #      */
  #     text: string;
  # }
  class TextDocumentContentChangeEvent < LSPBase
    attr_accessor :range # type: Range
    attr_accessor :rangeLength # type: number
    attr_accessor :text # type: string

    def initialize(initial_hash = nil)
      super
      @optional_method_names = %i[range rangeLength]
    end

    def from_h!(value)
      value = {} if value.nil?
      self.range = Range.new(value['range']) unless value['range'].nil?
      self.rangeLength = value['rangeLength']
      self.text = value['text']
      self
    end
  end
end

# rubocop:enable Layout/EmptyLinesAroundClassBody
# rubocop:enable Lint/UselessAssignment
# rubocop:enable Style/AsciiComments
