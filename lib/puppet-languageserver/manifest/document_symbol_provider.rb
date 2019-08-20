# frozen_string_literal: true

module PuppetLanguageServer
  module Manifest
    module DocumentSymbolProvider
      def self.workspace_symbols(query, object_cache)
        query = '' if query.nil?
        result = []
        object_cache.all_objects do |key, item|
          key_string = key.to_s
          next unless query.empty? || key_string.include?(query)
          case item
          when PuppetLanguageServer::Sidecar::Protocol::PuppetType
            result << LSP::SymbolInformation.new(
              'name'     => key_string,
              'kind'     => LSP::SymbolKind::METHOD,
              'location' => {
                'uri'   => PuppetLanguageServer::UriHelper.build_file_uri(item.source),
                # Don't have char pos for functions so just pick extreme values
                'range' => LSP.create_range(item.line, 0, item.line, 1024)
              }
            )

          when PuppetLanguageServer::Sidecar::Protocol::PuppetFunction
            result << LSP::SymbolInformation.new(
              'name'     => key_string,
              'kind'     => LSP::SymbolKind::FUNCTION,
              'location' => {
                'uri'   => PuppetLanguageServer::UriHelper.build_file_uri(item.source),
                # Don't have char pos for functions so just pick extreme values
                'range' => LSP.create_range(item.line, 0, item.line, 1024)
              }
            )

          when PuppetLanguageServer::Sidecar::Protocol::PuppetClass
            result << LSP::SymbolInformation.new(
              'name'     => key_string,
              'kind'     => LSP::SymbolKind::CLASS,
              'location' => {
                'uri'   => PuppetLanguageServer::UriHelper.build_file_uri(item.source),
                # Don't have char pos for functions so just pick extreme values
                'range' => LSP.create_range(item.line, 0, item.line, 1024)
              }
            )

          else
            PuppetLanguageServer.log_message(:warn, "[Manifest::DocumentSymbolProvider] Unknown object type #{item.class}")
          end
        end
        result
      end

      def self.extract_document_symbols(content, options = {})
        options = {
          :tasks_mode => false
        }.merge(options)
        parser = Puppet::Pops::Parser::Parser.new
        result = parser.singleton_parse_string(content, options[:tasks_mode], '')

        if result.model.respond_to? :eAllContents
          # We are unable to build a document symbol tree for Puppet 4 AST
          return []
        end
        symbols = []
        recurse_document_symbols(result.model, '', nil, symbols) # []

        symbols
      end

      def self.create_range(offset, length, locator)
        start_line = locator.line_for_offset(offset) - 1
        start_char = locator.pos_on_line(offset) - 1
        end_line = locator.line_for_offset(offset + length) - 1
        end_char = locator.pos_on_line(offset + length) - 1

        LSP.create_range(start_line, start_char, end_line, end_char)
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
          this_symbol = LSP::DocumentSymbol.new(
            'name'           => object.type_name.value,
            'kind'           => LSP::SymbolKind::METHOD,
            'detail'         => object.type_name.value,
            'range'          => create_range(object.offset, object.length, object.locator),
            'selectionRange' => create_range(object.offset, object.length, object.locator),
            'children'       => []
          )

        when 'Puppet::Pops::Model::ResourceBody'
          # We modify the parent symbol with the resource information,
          # mainly we care about the resource title.
          parentsymbol.name = parentsymbol.name + ': ' + locator_text(object.title.offset, object.title.length, object.title.locator)
          parentsymbol.detail = parentsymbol.name
          parentsymbol.selectionRange = create_range(object.title.offset, object.title.length, object.locator)

        when 'Puppet::Pops::Model::AttributeOperation'
          attr_name = object.attribute_name
          this_symbol = LSP::DocumentSymbol.new(
            'name'           => attr_name,
            'kind'           => LSP::SymbolKind::VARIABLE,
            'detail'         => attr_name,
            'range'          => create_range(object.offset, object.length, object.locator),
            'selectionRange' => create_range(object.offset, attr_name.length, object.locator),
            'children'       => []
          )

        # Puppet Class
        when 'Puppet::Pops::Model::HostClassDefinition'
          this_symbol = LSP::DocumentSymbol.new(
            'name'           => object.name,
            'kind'           => LSP::SymbolKind::CLASS,
            'detail'         => object.name,
            'range'          => create_range(object.offset, object.length, object.locator),
            'selectionRange' => create_range(object.offset, object.length, object.locator),
            'children'       => []
          )
          # Load in the class parameters
          object.parameters.each do |param|
            param_symbol = LSP::DocumentSymbol.new(
              'name'           => '$' + param.name,
              'kind'           => LSP::SymbolKind::PROPERTY,
              'detail'         => '$' + param.name,
              'range'          => create_range(param.offset, param.length, param.locator),
              'selectionRange' => create_range(param.offset, param.length, param.locator),
              'children'       => []
            )
            this_symbol.children.push(param_symbol)
          end

        # Puppet Defined Type
        when 'Puppet::Pops::Model::ResourceTypeDefinition'
          this_symbol = LSP::DocumentSymbol.new(
            'name'           => object.name,
            'kind'           => LSP::SymbolKind::CLASS,
            'detail'         => object.name,
            'range'          => create_range(object.offset, object.length, object.locator),
            'selectionRange' => create_range(object.offset, object.length, object.locator),
            'children'       => []
          )
          # Load in the class parameters
          object.parameters.each do |param|
            param_symbol = LSP::DocumentSymbol.new(
              'name'           => '$' + param.name,
              'kind'           => LSP::SymbolKind::FIELD,
              'detail'         => '$' + param.name,
              'range'          => create_range(param.offset, param.length, param.locator),
              'selectionRange' => create_range(param.offset, param.length, param.locator),
              'children'       => []
            )
            this_symbol['children'].push(param_symbol)
          end

        when 'Puppet::Pops::Model::AssignmentExpression'
          this_symbol = LSP::DocumentSymbol.new(
            'name'           => '$' + object.left_expr.expr.value,
            'kind'           => LSP::SymbolKind::VARIABLE,
            'detail'         => '$' + object.left_expr.expr.value,
            'range'          => create_range(object.left_expr.offset, object.left_expr.length, object.left_expr.locator),
            'selectionRange' => create_range(object.left_expr.offset, object.left_expr.length, object.left_expr.locator),
            'children'       => []
          )

        # Puppet Plan
        when 'Puppet::Pops::Model::PlanDefinition'
          this_symbol = LSP::DocumentSymbol.new(
            'name'           => object.name,
            'kind'           => LSP::SymbolKind::CLASS,
            'detail'         => object.name,
            'range'          => create_range(object.offset, object.length, object.locator),
            'selectionRange' => create_range(object.offset, object.length, object.locator),
            'children'       => []
          )
          # Load in the class parameters
          object.parameters.each do |param|
            param_symbol = LSP::DocumentSymbol.new(
              'name'           => '$' + param.name,
              'kind'           => LSP::SymbolKind::CLASS,
              'detail'         => '$' + param.name,
              'range'          => create_range(param.offset, param.length, param.locator),
              'selectionRange' => create_range(param.offset, param.length, param.locator),
              'children'       => []
            )
            this_symbol['children'].push(param_symbol)
          end
        end

        object._pcore_contents do |item|
          recurse_document_symbols(item, path, this_symbol.nil? ? parentsymbol : this_symbol, symbollist)
        end

        return if this_symbol.nil?
        parentsymbol.nil? ? symbollist.push(this_symbol) : parentsymbol.children.push(this_symbol)
      end
    end
  end
end
