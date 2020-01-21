# frozen_string_literal: true

module PuppetLanguageServer
  module Manifest
    module HoverProvider
      def self.resolve(content, line_num, char_num, options = {})
        options = {
          :tasks_mode => false
        }.merge(options)
        result = PuppetLanguageServer::PuppetParserHelper.object_under_cursor(content, line_num, char_num,
                                                                              :disallowed_classes => [Puppet::Pops::Model::QualifiedName, Puppet::Pops::Model::BlockExpression],
                                                                              :tasks_mode         => options[:tasks_mode])
        return LSP::Hover.new if result.nil?

        path = result[:path]
        item = result[:model]

        content = nil
        case item.class.to_s
        when 'Puppet::Pops::Model::ResourceExpression'
          content = get_resource_expression_content(item)
        when 'Puppet::Pops::Model::LiteralString'
          if path[-1].class == Puppet::Pops::Model::AccessExpression
            expr = path[-1].left_expr.expr.value

            content = get_hover_content_for_access_expression(path, expr)
          elsif path[-1].class == Puppet::Pops::Model::ResourceBody
            # We are hovering over the resource name
            content = get_resource_expression_content(path[-2])
          end
        when 'Puppet::Pops::Model::VariableExpression'
          expr = item.expr.value

          content = get_hover_content_for_access_expression(path, expr)
        when 'Puppet::Pops::Model::CallNamedFunctionExpression'
          content = get_call_named_function_expression_content(item, options[:tasks_mode])
        when 'Puppet::Pops::Model::AttributeOperation'
          # Get the parent resource class
          distance_up_ast = -1
          parent_klass = path[distance_up_ast]
          while !parent_klass.nil? && parent_klass.class.to_s != 'Puppet::Pops::Model::ResourceBody'
            distance_up_ast -= 1
            parent_klass = path[distance_up_ast]
          end
          raise "Unable to find suitable parent object for object of type #{item.class}" if parent_klass.nil?

          resource_type_name = path[distance_up_ast - 1].type_name.value
          # Check if it's a Puppet Type
          resource_object = PuppetLanguageServer::PuppetHelper.get_type(resource_type_name)
          unless resource_object.nil?
            # Check if it's a property
            attribute = resource_object.attributes[item.attribute_name.intern]
            if attribute[:type] == :property
              content = get_attribute_type_property_content(resource_object, item.attribute_name.intern)
            elsif attribute[:type] == :param
              content = get_attribute_type_parameter_content(resource_object, item.attribute_name.intern)
            end
          end
          # Check if it's a Puppet Class / Defined Type
          if resource_object.nil?
            resource_object = PuppetLanguageServer::PuppetHelper.get_class(resource_type_name)
            content = get_attribute_class_parameter_content(resource_object, item.attribute_name) unless resource_object.nil?
          end
          raise "#{resource_type_name} is not a valid puppet type, class or defined type" if resource_object.nil?
        when 'Puppet::Pops::Model::QualifiedReference'
          # https://github.com/puppetlabs/puppet-specifications/blob/master/language/names.md#names
          # Datatypes have to start with uppercase and can be fully qualified
          if item.cased_value =~ /^[A-Z][a-zA-Z:0-9]*$/ # rubocop:disable Style/GuardClause
            content = get_puppet_datatype_content(item, options[:tasks_mode])
          else
            raise "#{item.cased_value} is an unknown QualifiedReference"
          end
        else
          raise "Unable to generate Hover information for object of type #{item.class}"
        end

        LSP::Hover.new('contents' => content)
      end

      def self.get_hover_content_for_access_expression(path, expr)
        if expr == 'facts'
          # We are dealing with the facts variable
          # Just get the first part of the array and display that
          fact_array = path[-1]
          if fact_array.respond_to? :eContents
            fact_array_content = fact_array.eContents
          else
            fact_array_content = []
            fact_array._pcore_contents { |item| fact_array_content.push item }
          end

          if fact_array_content.length > 1
            factname = fact_array_content[1].value
            content = get_fact_content(factname)
          end
        elsif expr.start_with?('::') && expr.rindex(':') == 1
          # We are dealing with a top local scope variable - Possible fact name
          factname = expr.slice(2, expr.length - 2)
          content = get_fact_content(factname)
        else
          # Could be a flatout fact name.  May not *shrugs*.  That method of access is deprecated
          content = get_fact_content(expr)
        end

        content
      end

      # Content generation functions
      def self.get_fact_content(factname)
        fact = PuppetLanguageServer::FacterHelper.fact(factname)
        return nil if fact.nil?
        value = fact.value
        content = "**#{factname}** Fact\n\n"

        if value.is_a?(Hash)
          content = content + "```\n" + JSON.pretty_generate(value) + "\n```"
        else
          content += value.to_s
        end

        content
      end

      def self.get_attribute_type_parameter_content(item_type, param)
        param_type = item_type.attributes[param]
        content = "**#{param}** Parameter"
        content += "\n\n#{param_type[:doc]}" unless param_type[:doc].nil?
        content
      end

      def self.get_attribute_type_property_content(item_type, property)
        prop_type = item_type.attributes[property]
        content = "**#{property}** Property"
        content += "\n\n(_required_)" if prop_type[:required?]
        content += "\n\n#{prop_type[:doc]}" unless prop_type[:doc].nil?
        content
      end

      def self.get_attribute_class_parameter_content(item_class, param)
        param_type = item_class.parameters[param]
        return nil if param_type.nil?
        content = "**#{param}** Parameter"
        content += "\n\n#{param_type[:doc]}" unless param_type[:doc].nil?
        content
      end

      def self.get_call_named_function_expression_content(item, tasks_mode)
        func_name = item.functor_expr.value

        func_info = PuppetLanguageServer::PuppetHelper.function(func_name, tasks_mode)
        raise "Function #{func_name} does not exist" if func_info.nil?

        content = "**#{func_name}** Function"
        content += "\n\n" + func_info.doc unless func_info.doc.nil?

        content
      end

      def self.get_resource_expression_content(item)
        # Get an instance of the type
        item_object = PuppetLanguageServer::PuppetHelper.get_type(item.type_name.value)
        return get_puppet_type_content(item_object) unless item_object.nil?
        item_object = PuppetLanguageServer::PuppetHelper.get_class(item.type_name.value)
        return get_puppet_class_content(item_object) unless item_object.nil?
        raise "#{item.type_name.value} is not a valid puppet type"
      end

      def self.get_puppet_type_content(item_type)
        content = "**#{item_type.key}** Resource\n\n"
        content += "\n\n#{item_type.doc}" unless item_type.doc.nil?
        content += "\n\n---\n"
        item_type.attributes.keys.sort.each do |attr|
          content += "* #{attr}\n"
        end

        content
      end
      private_class_method :get_puppet_type_content

      def self.get_puppet_class_content(item_class)
        content = "**#{item_class.key}** Resource"
        content += "\n\n#{item_class.doc}" unless item_class.doc.nil?
        unless item_class.parameters.count.zero?
          content += "\n\n---\n"
          item_class.parameters.sort.each do |name, _param|
            content += "* #{name}\n"
          end
        end
        content.strip
      end
      private_class_method :get_puppet_class_content

      def self.get_puppet_datatype_content(item, tasks_mode)
        dt_info = PuppetLanguageServer::PuppetHelper.datatype(item.cased_value, tasks_mode)
        raise "DataType #{item.cased_value} does not exist" if dt_info.nil?

        content = "**#{item.cased_value}** Data Type"
        content += ' Alias' if dt_info.is_type_alias
        content += "\n\n" + dt_info.doc unless dt_info.doc.nil?

        content += "\n\nAlias of `#{dt_info.alias_of}`" if dt_info.is_type_alias
        content
      end
      private_class_method :get_puppet_datatype_content
    end
  end
end
