# frozen_string_literal: true

# DO NOT MODIFY. This file is built automatically
# LSP Enumerations

# rubocop:disable Layout/EmptyLinesAroundClassBody
# rubocop:disable Lint/UselessAssignment
# rubocop:disable Style/AsciiComments

module LSP
  module DiagnosticSeverity
    ERROR = 1
    WARNING = 2
    INFORMATION = 3
    HINT = 4
  end

  module MarkupKind
    PLAINTEXT = 'plaintext'
    MARKDOWN = 'markdown'
  end

  module CompletionItemKind
    TEXT = 1
    METHOD = 2
    FUNCTION = 3
    CONSTRUCTOR = 4
    FIELD = 5
    VARIABLE = 6
    CLASS = 7
    INTERFACE = 8
    MODULE = 9
    PROPERTY = 10
    UNIT = 11
    VALUE = 12
    ENUM = 13
    KEYWORD = 14
    SNIPPET = 15
    COLOR = 16
    FILE = 17
    REFERENCE = 18
    FOLDER = 19
    ENUMMEMBER = 20
    CONSTANT = 21
    STRUCT = 22
    EVENT = 23
    OPERATOR = 24
    TYPEPARAMETER = 25
  end

  module InsertTextFormat
    PLAINTEXT = 1
    SNIPPET = 2
  end

  module DocumentHighlightKind
    TEXT = 1
    READ = 2
    WRITE = 3
  end

  module SymbolKind
    FILE = 1
    MODULE = 2
    NAMESPACE = 3
    PACKAGE = 4
    CLASS = 5
    METHOD = 6
    PROPERTY = 7
    FIELD = 8
    CONSTRUCTOR = 9
    ENUM = 10
    INTERFACE = 11
    FUNCTION = 12
    VARIABLE = 13
    CONSTANT = 14
    STRING = 15
    NUMBER = 16
    BOOLEAN = 17
    ARRAY = 18
    OBJECT = 19
    KEY = 20
    NULL = 21
    ENUMMEMBER = 22
    STRUCT = 23
    EVENT = 24
    OPERATOR = 25
    TYPEPARAMETER = 26
  end

  module CodeActionKind
    QUICKFIX = 'quickfix'
    REFACTOR = 'refactor'
    REFACTOREXTRACT = 'refactor.extract'
    REFACTORINLINE = 'refactor.inline'
    REFACTORREWRITE = 'refactor.rewrite'
    SOURCE = 'source'
    SOURCEORGANIZEIMPORTS = 'source.organizeImports'
  end

  module TextDocumentSaveReason
    MANUAL = 1
    AFTERDELAY = 2
    FOCUSOUT = 3
  end

  module ResourceOperationKind
    CREATE = 'create'
    RENAME = 'rename'
    DELETE = 'delete'
  end

  module FailureHandlingKind
    ABORT = 'abort'
    TRANSACTIONAL = 'transactional'
    TEXTONLYTRANSACTIONAL = 'textOnlyTransactional'
    UNDO = 'undo'
  end

  module TextDocumentSyncKind
    FULL = 1
    INCREMENTAL = 2
  end

  module MessageType
    ERROR = 1
    WARNING = 2
    INFO = 3
    LOG = 4
  end

  module FileChangeType
    CREATED = 1
    CHANGED = 2
    DELETED = 3
  end

  module CompletionTriggerKind
    INVOKED = 1
    TRIGGERCHARACTER = 2
    TRIGGERFORINCOMPLETECOMPLETIONS = 3
  end
end

# rubocop:enable Layout/EmptyLinesAroundClassBody
# rubocop:enable Lint/UselessAssignment
# rubocop:enable Style/AsciiComments
