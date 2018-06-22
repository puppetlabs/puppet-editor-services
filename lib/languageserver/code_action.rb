module LanguageServer
  # /**
  # * Params for the CodeActionRequest
  # */
  # interface CodeActionParams {
  #   /**
  #   * The document in which the command was invoked.
  #   */
  #   textDocument: TextDocumentIdentifier;

  #   /**
  #   * The range for which the command was invoked.
  #   */
  #   range: Range;

  #   /**
  #   * Context carrying additional information.
  #   */
  #   context: CodeActionContext;
  # }
  module CodeActionRequest
    def self.create(options)
      result = {}
      raise('textDocument is a required field for CodeActionRequest') if options['textDocument'].nil?
      raise('range is a required field for CodeActionRequest') if options['range'].nil?
      raise('context is a required field for CodeActionRequest') if options['context'].nil?

      result['textDocument'] = options['textDocument']
      result['range'] = options['range']
      result['context'] = CodeActionContext.create(options['context'])

      result
    end
  end

  # /**
  # * Contains additional diagnostic information about the context in which
  # * a code action is run.
  # */
  # interface CodeActionContext {
  #   /**
  #   * An array of diagnostics.
  #   */
  #   diagnostics: Diagnostic[];

  #   /**
  #   * Requested kind of actions to return.
  #   *
  #   * Actions not of this kind are filtered out by the client before being shown. So servers
  #   * can omit computing them.
  #   */
  #   only?: CodeActionKind[];
  # }
  module CodeActionContext
    def self.create(options)
      result = {}
      raise('diagnostics is a required field for CodeActionContext') if options['diagnostics'].nil?

      result['diagnostics'] = []

      options['diagnostics'].each do |diag|
        # TODO: Should really ask Diagnostic.create to create the object
        result['diagnostics'] << diag
      end
      result['only'] = options['only'] unless options['only'].nil?

      result
    end
  end

  # /**
  # * A code action represents a change that can be performed in code, e.g. to fix a problem or
  # * to refactor code.
  # *
  # * A CodeAction must set either `edit` and/or a `command`. If both are supplied, the `edit` is applied first, then the `command` is executed.
  # */
  # export interface CodeAction {

  # /**
  # * A short, human-readable, title for this code action.
  # */
  # title: string;

  # /**
  # * The kind of the code action.
  # *
  # * Used to filter code actions.
  # */
  # kind?: CodeActionKind;

  # /**
  # * The diagnostics that this code action resolves.
  # */
  # diagnostics?: Diagnostic[];

  # /**
  # * The workspace edit this code action performs.
  # */
  # edit?: WorkspaceEdit;

  # /**
  # * A command this code action executes. If a code action
  # * provides an edit and a command, first the edit is
  # * executed and then the command.
  # */
  # command?: Command;
  # }
  module CodeAction
    def self.create(options)
      result = {}
      raise('title is a required field for CodeAction') if options['title'].nil?

      result['title']       = options['title']
      result['kind']        = options['kind'] unless options['kind'].nil?
      result['diagnostics'] = options['diagnostics'] unless options['diagnostics'].nil?
      result['edit']        = options['edit'] unless options['edit'].nil?
      result['command']     = options['command'] unless options['command'].nil?

      result
    end
  end
end
