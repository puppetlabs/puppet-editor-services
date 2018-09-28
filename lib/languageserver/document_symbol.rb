module LanguageServer
#   /**
#   * Represents programming constructs like variables, classes, interfaces etc. that appear in a document. Document symbols can be
#   * hierarchical and they have two ranges: one that encloses its definition and one that points to its most interesting range,
#   * e.g. the range of an identifier.
#   */
#  export class DocumentSymbol {
#    /**
#     * The name of this symbol.
#     */
#    name: string;
#    /**
#     * More detail for this symbol, e.g the signature of a function.
#     */
#    detail?: string;
#    /**
#     * The kind of this symbol.
#     */
#    kind: SymbolKind;
#    /**
#     * Indicates if this symbol is deprecated.
#     */
#    deprecated?: boolean;
#    /**
#     * The range enclosing this symbol not including leading/trailing whitespace but everything else
#     * like comments. This information is typically used to determine if the clients cursor is
#     * inside the symbol to reveal in the symbol in the UI.
#     */
#    range: Range;
#    /**
#     * The range that should be selected and revealed when this symbol is being picked, e.g the name of a function.
#     * Must be contained by the `range`.
#     */
#    selectionRange: Range;
#    /**
#     * Children of this symbol, e.g. properties of a class.
#     */
#    children?: DocumentSymbol[];
#  }
  module DocumentSymbol
    def self.create(options)
      result = {}
      raise('name is a required field for DocumentSymbol') if options['name'].nil?
      raise('kind is a required field for DocumentSymbol') if options['kind'].nil?
      raise('range is a required field for DocumentSymbol') if options['range'].nil?
      raise('selectionRange is a required field for DocumentSymbol') if options['selectionRange'].nil?
      
      result['name']           = options['name']
      result['kind']           = options['kind']
      result['detail']         = options['detail'] unless options['detail'].nil?
      result['deprecated']     = options['deprecated'] unless options['deprecated'].nil?
      result['children']       = options['children'] unless options['children'].nil?

      result['range'] = {
        'start' => {
          'line'      => options['range'][0],
          'character' => options['range'][1],
        },
        'end' => {
          'line'      => options['range'][2],
          'character' => options['range'][3],
        }
      }

      result['selectionRange'] = {
        'start' => {
          'line'      => options['selectionRange'][0],
          'character' => options['selectionRange'][1],
        },
        'end' => {
          'line'      => options['selectionRange'][2],
          'character' => options['selectionRange'][3],
        }
      }

      result
    end
  end
end
