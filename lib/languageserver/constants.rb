# Reference - https://github.com/Microsoft/language-server-protocol/blob/master/protocol.md
module LanguageServer
  COMPLETIONITEMKIND_TEXT = 1
  COMPLETIONITEMKIND_METHOD = 2
  COMPLETIONITEMKIND_FUNCTION = 3
  COMPLETIONITEMKIND_CONSTRUCTOR = 4
  COMPLETIONITEMKIND_FIELD = 5
  COMPLETIONITEMKIND_VARIABLE = 6
  COMPLETIONITEMKIND_CLASS = 7
  COMPLETIONITEMKIND_INTERFACE = 8
  COMPLETIONITEMKIND_MODULE = 9
  COMPLETIONITEMKIND_PROPERTY = 10
  COMPLETIONITEMKIND_UNIT = 11
  COMPLETIONITEMKIND_VALUE = 12
  COMPLETIONITEMKIND_ENUM = 13
  COMPLETIONITEMKIND_KEYWORD = 14
  COMPLETIONITEMKIND_SNIPPET = 15
  COMPLETIONITEMKIND_COLOR = 16
  COMPLETIONITEMKIND_FILE = 17
  COMPLETIONITEMKIND_REFERENCE = 18

  INSERTTEXTFORMAT_PLAINTEXT = 1
  INSERTTEXTFORMAT_SNIPPET = 2

  SYMBOLKIND_FILE = 1
  SYMBOLKIND_MODULE = 2
  SYMBOLKIND_NAMESPACE = 3
  SYMBOLKIND_PACKAGE = 4
  SYMBOLKIND_CLASS = 5
  SYMBOLKIND_METHOD = 6
  SYMBOLKIND_PROPERTY = 7
  SYMBOLKIND_FIELD = 8
  SYMBOLKIND_CONSTRUCTOR = 9
  SYMBOLKIND_ENUM = 10
  SYMBOLKIND_INTERFACE = 11
  SYMBOLKIND_FUNCTION = 12
  SYMBOLKIND_VARIABLE = 13
  SYMBOLKIND_CONSTANT = 14
  SYMBOLKIND_STRING = 15
  SYMBOLKIND_NUMBER = 16
  SYMBOLKIND_BOOLEAN = 17
  SYMBOLKIND_ARRAY = 18
  SYMBOLKIND_OBJECT     = 19
  SYMBOLKIND_KEY        = 20
  SYMBOLKIND_NULL       = 21
  SYMBOLKIND_ENUMMEMBER = 22
  SYMBOLKIND_STRUCT     = 23
  SYMBOLKIND_EVENT      = 24
  SYMBOLKIND_OPERATOR   = 25

  TEXTDOCUMENTSYNCKIND_NONE = 0
  TEXTDOCUMENTSYNCKIND_FULL = 1
  TEXTDOCUMENTSYNCKIND_INCREMENTAL = 2

  DIAGNOSTICSEVERITY_ERROR = 1
  DIAGNOSTICSEVERITY_WARNING = 2
  DIAGNOSTICSEVERITY_INFORMATION = 3
  DIAGNOSTICSEVERITY_HINT = 4

  MESSAGE_TYPE_ERROR = 1
  MESSAGE_TYPE_WARNING = 2
  MESSAGE_TYPE_INFO = 3
  MESSAGE_TYPE_LOG = 2

  # /**
  # * A set of predefined code action kinds
  # */
  # export namespace CodeActionKind {
  #   /**
  #   * Base kind for quickfix actions: 'quickfix'
  #   */
  #   export const QuickFix: CodeActionKind = 'quickfix';

  #   /**
  #   * Base kind for refactoring actions: 'refactor'
  #   */
  #   export const Refactor: CodeActionKind = 'refactor';

  #   /**
  #   * Base kind for refactoring extraction actions: 'refactor.extract'
  #   *
  #   * Example extract actions:
  #   *
  #   * - Extract method
  #   * - Extract function
  #   * - Extract variable
  #   * - Extract interface from class
  #   * - ...
  #   */
  #   export const RefactorExtract: CodeActionKind = 'refactor.extract';

  #   /**
  #   * Base kind for refactoring inline actions: 'refactor.inline'
  #   *
  #   * Example inline actions:
  #   *
  #   * - Inline function
  #   * - Inline variable
  #   * - Inline constant
  #   * - ...
  #   */
  #   export const RefactorInline: CodeActionKind = 'refactor.inline';

  #   /**
  #   * Base kind for refactoring rewrite actions: 'refactor.rewrite'
  #   *
  #   * Example rewrite actions:
  #   *
  #   * - Convert JavaScript function to class
  #   * - Add or remove parameter
  #   * - Encapsulate field
  #   * - Make method static
  #   * - Move method to base class
  #   * - ...
  #   */
  #   export const RefactorRewrite: CodeActionKind = 'refactor.rewrite';

  #   /**
  #   * Base kind for source actions: `source`
  #   *
  #   * Source code actions apply to the entire file.
  #   */
  #   export const Source: CodeActionKind = 'source';

  #   /**
  #   * Base kind for an organize imports source action: `source.organizeImports`
  #   */
  #   export const SourceOrganizeImports: CodeActionKind = 'source.organizeImports';
  # }
  CODEACTIONKIND_QUICKFIX             = 'quickfix'.freeze
  CODEACTIONKIND_REFACTOR             = 'refactor'.freeze
  CODEACTIONKIND_REFACTOREXTRACT      = 'refactor.extract'.freeze
  CODEACTIONKIND_REFACTORINLINE       = 'refactor.inline'.freeze
  CODEACTIONKIND_REFACTORREWRITE      = 'refactor.rewrite'.freeze
  CODEACTIONKIND_SOURCE               = 'source'.freeze
  CODEACTIONKIND_SOURCEORGANIZEIMPORS = 'source.organizeImports'.freeze
end
