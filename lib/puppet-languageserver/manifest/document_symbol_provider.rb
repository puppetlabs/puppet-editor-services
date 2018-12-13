module PuppetLanguageServer
  module Manifest
    module DocumentSymbolProvider
      def self.workspace_symbols(query)
        query = '' if query.nil?
        result = []
        PuppetLanguageServer::PuppetHelper.all_objects do |key, item|
          key_string = key.to_s
          next unless key_string.include?(query)
          case item
          when PuppetLanguageServer::PuppetHelper::PuppetType
            result << LanguageServer::SymbolInformation.create(
              'name'     => key_string,
              'kind'     => LanguageServer::SYMBOLKIND_METHOD,
              'location' => LanguageServer::Location.create(
                'uri'      => PuppetLanguageServer::UriHelper.build_file_uri(item.source),
                'fromline' => item.line,
                'fromchar' => 0, # Don't have char pos for types
                'toline'   => item.line,
                'tochar'   => 1024, # Don't have char pos for types
              )
            )

          when PuppetLanguageServer::PuppetHelper::PuppetFunction
            result << LanguageServer::SymbolInformation.create(
              'name'     => key_string,
              'kind'     => LanguageServer::SYMBOLKIND_FUNCTION,
              'location' => LanguageServer::Location.create(
                'uri'      => PuppetLanguageServer::UriHelper.build_file_uri(item.source),
                'fromline' => item.line,
                'fromchar' => 0, # Don't have char pos for functions
                'toline'   => item.line,
                'tochar'   => 1024, # Don't have char pos for functions
              )
            )

          when PuppetLanguageServer::PuppetHelper::PuppetClass
            result << LanguageServer::SymbolInformation.create(
              'name'     => key_string,
              'kind'     => LanguageServer::SYMBOLKIND_CLASS,
              'location' => LanguageServer::Location.create(
                'uri'      => PuppetLanguageServer::UriHelper.build_file_uri(item.source),
                'fromline' => item.line,
                'fromchar' => 0, # Don't have char pos for classes
                'toline'   => item.line,
                'tochar'   => 1024, # Don't have char pos for classes
              )
            )
          end
        end
        result
      end

      def self.extract_document_symbols(content)
        parser = Puppet::Pops::Parser::Parser.new
        result = parser.parse_string(content, '')

        if result.model.respond_to? :eAllContents
          # We are unable to build a document symbol tree for Puppet 4 AST
          return []
        end
        symbols = []
        recurse_document_symbols(result.model, '', nil, symbols) # []

        symbols
      end

      def self.create_range_array(offset, length, locator)
        start_line = locator.line_for_offset(offset) - 1
        start_char = locator.pos_on_line(offset) - 1
        end_line = locator.line_for_offset(offset + length) - 1
        end_char = locator.pos_on_line(offset + length) - 1

        [start_line, start_char, end_line, end_char]
      end

      def self.create_range_object(offset, length, locator)
        result = create_range_array(offset, length, locator)
        {
          'start' => {
            'line'      => result[0],
            'character' => result[1]
          },
          'end'   => {
            'line'      => result[2],
            'character' => result[3]
          }
        }
      end

      def self.locator_text(offset, length, locator)
        locator.string.slice(offset, length)
      end

      def self.recurse_document_symbols(object, path, parentsymbol, symbollist)
        # POPS Object Model
        # https://github.com/puppetlabs/puppet/blob/master/lib/puppet/pops/model/ast.pp

        # Path is just an internal path for debugging
        # path = path + '/' + object.class.to_s[object.class.to_s.rindex('::')..-1]

        this_symbol = nil

        case object.class.to_s
        # Puppet Resources
        when 'Puppet::Pops::Model::ResourceExpression'
          this_symbol = LanguageServer::DocumentSymbol.create(
            'name'           => object.type_name.value,
            'kind'           => LanguageServer::SYMBOLKIND_METHOD,
            'detail'         => object.type_name.value,
            'range'          => create_range_array(object.offset, object.length, object.locator),
            'selectionRange' => create_range_array(object.offset, object.length, object.locator),
            'children'       => []
          )

        when 'Puppet::Pops::Model::ResourceBody'
          # We modify the parent symbol with the resource information,
          # mainly we care about the resource title.
          parentsymbol['name'] = parentsymbol['name'] + ': ' + locator_text(object.title.offset, object.title.length, object.title.locator)
          parentsymbol['detail'] = parentsymbol['name']
          parentsymbol['selectionRange'] = create_range_object(object.title.offset, object.title.length, object.locator)

        when 'Puppet::Pops::Model::AttributeOperation'
          attr_name = object.attribute_name
          this_symbol = LanguageServer::DocumentSymbol.create(
            'name'           => attr_name,
            'kind'           => LanguageServer::SYMBOLKIND_VARIABLE,
            'detail'         => attr_name,
            'range'          => create_range_array(object.offset, object.length, object.locator),
            'selectionRange' => create_range_array(object.offset, attr_name.length, object.locator),
            'children'       => []
          )

        # Puppet Class
        when 'Puppet::Pops::Model::HostClassDefinition'
          this_symbol = LanguageServer::DocumentSymbol.create(
            'name'           => object.name,
            'kind'           => LanguageServer::SYMBOLKIND_CLASS,
            'detail'         => object.name,
            'range'          => create_range_array(object.offset, object.length, object.locator),
            'selectionRange' => create_range_array(object.offset, object.length, object.locator),
            'children'       => []
          )
          # Load in the class parameters
          object.parameters.each do |param|
            param_symbol = LanguageServer::DocumentSymbol.create(
              'name'           => '$' + param.name,
              'kind'           => LanguageServer::SYMBOLKIND_PROPERTY,
              'detail'         => '$' + param.name,
              'range'          => create_range_array(param.offset, param.length, param.locator),
              'selectionRange' => create_range_array(param.offset, param.length, param.locator),
              'children'       => []
            )
            this_symbol['children'].push(param_symbol)
          end

        # Puppet Defined Type
        when 'Puppet::Pops::Model::ResourceTypeDefinition'
          this_symbol = LanguageServer::DocumentSymbol.create(
            'name'           => object.name,
            'kind'           => LanguageServer::SYMBOLKIND_CLASS,
            'detail'         => object.name,
            'range'          => create_range_array(object.offset, object.length, object.locator),
            'selectionRange' => create_range_array(object.offset, object.length, object.locator),
            'children'       => []
          )
          # Load in the class parameters
          object.parameters.each do |param|
            param_symbol = LanguageServer::DocumentSymbol.create(
              'name'           => '$' + param.name,
              'kind'           => LanguageServer::SYMBOLKIND_FIELD,
              'detail'         => '$' + param.name,
              'range'          => create_range_array(param.offset, param.length, param.locator),
              'selectionRange' => create_range_array(param.offset, param.length, param.locator),
              'children'       => []
            )
            this_symbol['children'].push(param_symbol)
          end

        when 'Puppet::Pops::Model::AssignmentExpression'
          this_symbol = LanguageServer::DocumentSymbol.create(
            'name'           => '$' + object.left_expr.expr.value,
            'kind'           => LanguageServer::SYMBOLKIND_VARIABLE,
            'detail'         => '$' + object.left_expr.expr.value,
            'range'          => create_range_array(object.left_expr.offset, object.left_expr.length, object.left_expr.locator),
            'selectionRange' => create_range_array(object.left_expr.offset, object.left_expr.length, object.left_expr.locator),
            'children'       => []
          )

        end

        object._pcore_contents do |item|
          recurse_document_symbols(item, path, this_symbol.nil? ? parentsymbol : this_symbol, symbollist)
        end

        return if this_symbol.nil?
        parentsymbol.nil? ? symbollist.push(this_symbol) : parentsymbol['children'].push(this_symbol)
      end
    end
  end
end
