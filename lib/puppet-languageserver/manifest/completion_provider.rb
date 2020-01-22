# frozen_string_literal: true

module PuppetLanguageServer
  module Manifest
    module CompletionProvider
      def self.complete(content, line_num, char_num, options = {})
        options = {
          :tasks_mode => false,
          :context    => nil # LSP::CompletionContext object
        }.merge(options)
        items = []
        incomplete = false
        is_trigger_char = !options[:context].nil? && options[:context].triggerKind == LSP::CompletionTriggerKind::TRIGGERCHARACTER

        result = PuppetLanguageServer::PuppetParserHelper.object_under_cursor(content, line_num, char_num,
                                                                              :multiple_attempts   => true,
                                                                              :disallowed_classes  => [Puppet::Pops::Model::QualifiedName, Puppet::Pops::Model::BlockExpression],
                                                                              :tasks_mode          => options[:tasks_mode],
                                                                              :remove_trigger_char => is_trigger_char)
        if result.nil?
          # We are in the root of the document.

          # Add keywords
          keywords(%w[class define node application site]) { |x| items << x }
          keywords(%w[plan]) { |x| items << x } if options[:tasks_mode]

          # Add resources
          all_resources { |x| items << x }

          all_functions(options[:tasks_mode]) { |x| items << x }

          response = LSP::CompletionList.new
          response.items = items
          response.isIncomplete = incomplete
          return response
        end

        item = result[:model]

        case item.class.to_s
        when 'Puppet::Pops::Model::VariableExpression'
          expr = item.expr.value

          # Complete for `$facts[...`
          all_facts { |x| items << x } if expr == 'facts'

        when 'Puppet::Pops::Model::HostClassDefinition', 'Puppet::Pops::Model::ResourceTypeDefinition'
          # We are in the root of a `class` or `define` statement

          # Add keywords
          keywords(%w[require contain]) { |x| items << x }

          # Add resources
          all_resources { |x| items << x }

        when 'Puppet::Pops::Model::PlanDefinition'
          # We are in the root of a `plan` statement

          # Add resources
          all_resources { |x| items << x }

          all_functions(options[:tasks_mode]) { |x| items << x }

        when 'Puppet::Pops::Model::ResourceExpression'
          # We are inside a resource definition.  Should display all available
          # properities and parameters.

          # Try Types first
          # The `class` pseudo resource type is actually used to set properties/params for the puppet type
          # specified in the resource title.
          # Ref: https://puppet.com/docs/puppet/5.3/lang_classes.html#using-resource-like-declarations
          item_value = item.type_name.value == 'class' && item.bodies.length == 1 ? item.bodies[0].title.value : item.type_name.value
          item_object = PuppetLanguageServer::PuppetHelper.get_type(item_value)
          unless item_object.nil?
            # Add Parameters
            item_object.attributes.select { |_name, data| data[:type] == :param }.each_key do |name|
              items << LSP::CompletionItem.new(
                'label'  => name.to_s,
                'kind'   => LSP::CompletionItemKind::PROPERTY,
                'detail' => 'Parameter',
                'data'   => {
                  'type'          => 'resource_parameter',
                  'param'         => name.to_s,
                  'resource_type' => item_value
                }
              )
            end
            # Add Properties
            item_object.attributes.select { |_name, data| data[:type] == :property }.each_key do |name|
              items << LSP::CompletionItem.new(
                'label'  => name.to_s,
                'kind'   => LSP::CompletionItemKind::PROPERTY,
                'detail' => 'Property',
                'data'   => {
                  'type'          => 'resource_property',
                  'prop'          => name.to_s,
                  'resource_type' => item_value
                }
              )
            end
            # TODO: What about meta parameters?
          end
          if item_object.nil?
            # Try Classes/Defined Types
            item_object = PuppetLanguageServer::PuppetHelper.get_class(item_value)
            unless item_object.nil?
              # Add Parameters
              item_object.parameters.each_key do |name|
                items << LSP::CompletionItem.new(
                  'label'  => name.to_s,
                  'kind'   => LSP::CompletionItemKind::PROPERTY,
                  'detail' => 'Parameter',
                  'data'   => {
                    'type'          => 'resource_class_parameter',
                    'param'         => name.to_s,
                    'resource_type' => item_value
                  }
                )
              end
            end
          end
        end

        response = LSP::CompletionList.new
        response.items = items
        response.isIncomplete = incomplete
        response
      end

      # BEGIN CompletionItem Helpers
      def self.keywords(keywords = [], &block)
        keywords.each do |keyword|
          item = LSP::CompletionItem.new(
            'label'  => keyword,
            'kind'   => LSP::CompletionItemKind::KEYWORD,
            'detail' => 'Keyword',
            'data'   => {
              'type' => 'keyword',
              'name' => keyword
            }
          )
          block.call(item) if block
        end
      end

      def self.all_facts(&block)
        PuppetLanguageServer::FacterHelper.fact_names.each do |name|
          item = LSP::CompletionItem.new(
            'label'      => name.to_s,
            'insertText' => "'#{name}'",
            'kind'       => LSP::CompletionItemKind::VARIABLE,
            'detail'     => 'Fact',
            'data'       => {
              'type' => 'variable_expr_fact',
              'expr' => name
            }
          )
          block.call(item) if block
        end
      end

      def self.all_resources(&block)
        # Find Puppet Types
        PuppetLanguageServer::PuppetHelper.type_names.each do |pup_type|
          item = LSP::CompletionItem.new(
            'label'  => pup_type,
            'kind'   => LSP::CompletionItemKind::MODULE,
            'detail' => 'Resource',
            'data'   => {
              'type' => 'resource_type',
              'name' => pup_type
            }
          )
          block.call(item) if block
        end
        # Find Puppet Classes/Defined Types
        PuppetLanguageServer::PuppetHelper.class_names.each do |pup_class|
          item = LSP::CompletionItem.new('label'  => pup_class,
                                         'kind'   => LSP::CompletionItemKind::MODULE,
                                         'detail' => 'Resource',
                                         'data'   => { 'type' => 'resource_class',
                                                       'name' => pup_class })
          block.call(item) if block
        end
      end

      def self.all_functions(tasks_mode, &block)
        PuppetLanguageServer::PuppetHelper.function_names(tasks_mode).each do |name|
          item = LSP::CompletionItem.new(
            'label'  => name.to_s,
            'kind'   => LSP::CompletionItemKind::FUNCTION,
            'detail' => 'Function',
            'data'   => {
              'type' => 'function',
              'name' => name.to_s
            }
          )
          block.call(item) if block
        end
      end
      # END Helpers

      # completion_item is an instance of LSP::CompletionItem
      def self.resolve(completion_item)
        result = completion_item.clone
        data = result.data
        case data['type']
        when 'variable_expr_fact'
          value = PuppetLanguageServer::FacterHelper.fact_value(data['expr'])
          # TODO: More things?
          result.documentation = value.to_s

        when 'keyword'
          case data['name']
          when 'class'
            result.documentation = 'Classes are named blocks of Puppet code that are stored in modules for later use and ' \
                                   'are not applied until they are invoked by name. They can be added to a node’s catalog ' \
                                   'by either declaring them in your manifests or assigning them from an ENC.'
            result.insertText = "# Class: $1\n#\n#\nclass ${1:name} {\n\t${2:# resources}\n}$0"
            result.insertTextFormat = LSP::InsertTextFormat::SNIPPET
          when 'define'
            result.documentation = 'Defined resource types (also called defined types or defines) are blocks of Puppet code ' \
                                   'that can be evaluated multiple times with different parameters. Once defined, they act ' \
                                   'like a new resource type: you can cause the block to be evaluated by declaring a resource ' \
                                   'of that new resource type.'
            result.insertText = "define ${1:name} () {\n\t${2:# resources}\n}$0"
            result.insertTextFormat = LSP::InsertTextFormat::SNIPPET
          when 'application'
            result.detail = 'Orchestrator'
            result.documentation = 'Application definitions are a lot like a defined resource type except that instead of defining ' \
                                   'a chunk of reusable configuration that applies to a single node, the application definition ' \
                                   'operates at a higher level. The components you declare inside an application can be individually '\
                                   'assigned to separate nodes you manage with Puppet.'
            result.insertText = "application ${1:name} () {\n\t${2:# resources}\n}$0"
            result.insertTextFormat = LSP::InsertTextFormat::SNIPPET
          when 'site'
            result.detail = 'Orchestrator'
            result.documentation = 'Within the site block, applications are declared like defined types. They can be declared any ' \
                                   'number of times, but their type and title combination must be unique within an environment.'
            result.insertText = "site ${1:name} () {\n\t${2:# applications}\n}$0"
            result.insertTextFormat = LSP::InsertTextFormat::SNIPPET
          end

        when 'function'
          # We don't know if this resolution is coming from a plan or not, so just assume it is
          item_type = PuppetLanguageServer::PuppetHelper.function(data['name'], true)
          return result if item_type.nil?
          result.documentation = item_type.doc unless item_type.doc.nil?
          unless item_type.nil? || item_type.signatures.count.zero?
            result.detail = item_type.signatures.map(&:key).join("\n\n")
            # The signature provider should handle suggestions after this, so just place the cursor ready for an opening bracket
            result.insertText = data['name'].to_s
            result.insertTextFormat = LSP::InsertTextFormat::PLAINTEXT
          end

        when 'resource_type'
          item_type = PuppetLanguageServer::PuppetHelper.get_type(data['name'])
          return result if item_type.nil?

          attr_names = []
          # Add required attributes.  Ignore namevars as they come from the resource title
          item_type.attributes.each { |name, item| attr_names.push(name.to_s) if item[:required?] && item[:isnamevar?] != true }
          # Remove the'ensure' param/property for now, and we'll re-add later
          attr_names.reject! { |item| item == 'ensure' }
          # The param/property list should initially sorted alphabetically
          attr_names.sort!
          # Add the 'ensure' param/property at the top if the resource supports it
          attr_names.insert(0, 'ensure') unless item_type.attributes.keys.find_index(:ensure).nil?
          # Get the longest string length for later hash-rocket padding
          max_length = -1
          attr_names.each { |name| max_length = name.length if name.length > max_length }

          # Generate the text snippet
          snippet = "#{data['name']} { '${1:title}':\n"
          attr_names.each_index do |index|
            name = attr_names[index]
            value_text = (name == 'ensure') ? 'present' : 'value' # rubocop:disable Style/TernaryParentheses  In this case it's easier to read.
            snippet += "\t#{name.ljust(max_length, ' ')} => '${#{index + 2}:#{value_text}}'\n"
          end
          snippet += '}'

          result.documentation = item_type.doc unless item_type.doc.nil?
          result.insertText = snippet
          result.insertTextFormat = LSP::InsertTextFormat::SNIPPET
        when 'resource_parameter'
          item_type = PuppetLanguageServer::PuppetHelper.get_type(data['resource_type'])
          return result if item_type.nil?
          param_type = item_type.attributes[data['param'].intern]
          unless param_type.nil?
            # TODO: More things?
            result.documentation = param_type[:doc] unless param_type[:doc].nil?
            result.insertText = "#{data['param']} => "
          end
        when 'resource_property'
          item_type = PuppetLanguageServer::PuppetHelper.get_type(data['resource_type'])
          return result if item_type.nil?
          prop_type = item_type.attributes[data['prop'].intern]
          unless prop_type.nil?
            # TODO: More things?
            result.documentation = prop_type[:doc] unless prop_type[:doc].nil?
            result.insertText = "#{data['prop']} => "
          end

        when 'resource_class'
          item_class = PuppetLanguageServer::PuppetHelper.get_class(data['name'])
          return result if item_class.nil?

          result.insertText = "#{data['name']} { '${1:title}':\n\t$0\n}"
          result.insertTextFormat = LSP::InsertTextFormat::SNIPPET
        when 'resource_class_parameter'
          item_class = PuppetLanguageServer::PuppetHelper.get_class(data['resource_type'])
          return result if item_class.nil?
          param_type = item_class.parameters[data['param']]
          unless param_type.nil?
            doc = ''
            doc += param_type[:type] unless param_type[:type].nil?
            doc += "---\n" + param_type[:doc] unless param_type[:doc].nil?
            result.documentation = doc
            result.insertText = "#{data['param']} => "
          end
        end

        result
      end
    end
  end
end
