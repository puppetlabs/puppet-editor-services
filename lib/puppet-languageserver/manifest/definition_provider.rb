# frozen_string_literal: true

module PuppetLanguageServer
  module Manifest
    module DefinitionProvider
      def self.find_definition(content, line_num, char_num, options = {})
        options = {
          :tasks_mode => false
        }.merge(options)
        result = PuppetLanguageServer::PuppetParserHelper.object_under_cursor(content, line_num, char_num,
                                                                              :disallowed_classes => [Puppet::Pops::Model::BlockExpression],
                                                                              :tasks_mode         => options[:tasks_mode])
        return nil if result.nil?

        path = result[:path]
        item = result[:model]

        response = []
        case item.class.to_s
        when 'Puppet::Pops::Model::CallNamedFunctionExpression'
          func_name = item.functor_expr.value
          response << function_name(func_name)

        when 'Puppet::Pops::Model::LiteralString'
          # LiteralString could be anything.  Context is the key here
          parent = path.last

          # What if it's a resource name.  Then the Literal String must be the same as the Resource Title
          # e.g.
          # class { 'testclass':    <--- testclass would be the LiteralString inside a ResourceBody
          # }
          if !parent.nil? &&
             parent.class.to_s == 'Puppet::Pops::Model::ResourceBody' &&
             parent.title.value == item.value
            resource_name = item.value
            response << type_or_class(resource_name)
          end

        when 'Puppet::Pops::Model::QualifiedName'
          # Qualified names could be anything.  Context is the key here
          parent = path.last

          # What if it's a function name.  Then the Qualified name must be the same as the function name
          if !parent.nil? &&
             parent.class.to_s == 'Puppet::Pops::Model::CallNamedFunctionExpression' &&
             parent.functor_expr.value == item.value
            func_name = item.value
            response << function_name(func_name)
          end
          # What if it's an "include <class>" call
          if !parent.nil? && parent.class.to_s == 'Puppet::Pops::Model::CallNamedFunctionExpression' && parent.functor_expr.value == 'include'
            resource_name = item.value
            response << type_or_class(resource_name)
          end
          # What if it's the name of a resource type or class
          if !parent.nil? && parent.class.to_s == 'Puppet::Pops::Model::ResourceExpression'
            resource_name = item.value
            response << type_or_class(resource_name)
          end

        when 'Puppet::Pops::Model::ResourceExpression'
          resource_name = item.type_name.value
          response << type_or_class(resource_name)

        else
          raise "Unable to generate Defintion information for object of type #{item.class}"
        end

        response.compact
      end

      def self.type_or_class(resource_name)
        # Strip the leading double-colons for root resource names
        resource_name = resource_name.slice(2, resource_name.length - 2) if resource_name.start_with?('::')
        item = PuppetLanguageServer::PuppetHelper.get_type(resource_name)
        item = PuppetLanguageServer::PuppetHelper.get_class(resource_name) if item.nil?
        unless item.nil?
          return LSP::Location.new(
            'uri'   => PuppetLanguageServer::UriHelper.build_file_uri(item.source),
            'range' => LSP.create_range(item.line, 0, item.line, 1024)
          )
        end
        nil
      end
      private_class_method :type_or_class

      def self.function_name(func_name)
        item = PuppetLanguageServer::PuppetHelper.function(func_name)
        return nil if item.nil? || item.source.nil? || item.line.nil?
        LSP::Location.new(
          'uri'   => 'file:///' + item.source,
          'range' => LSP.create_range(item.line, 0, item.line, 1024)
        )
      end
      private_class_method :function_name
    end
  end
end
