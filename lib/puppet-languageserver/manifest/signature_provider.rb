# frozen_string_literal: true

module PuppetLanguageServer
  module Manifest
    module SignatureProvider
      def self.signature_help(content, line_num, char_num, options = {})
        options = {
          :tasks_mode => false
        }.merge(options)

        result = PuppetLanguageServer::PuppetParserHelper.object_under_cursor(content, line_num, char_num,
                                                                              :multiple_attempts   => false,
                                                                              :tasks_mode          => options[:tasks_mode],
                                                                              :remove_trigger_char => false)
        response = LSP::SignatureHelp.new.from_h!('signatures' => [], 'activeSignature' => nil, 'activeParameter' => nil)
        # We are in the root of the document so no signatures here.
        return response if result.nil?

        item    = result[:model]
        path    = result[:path]
        locator = result[:locator]

        function_ast_object = nil
        # Try and find the acutal function object within the AST
        if item.class.to_s == 'Puppet::Pops::Model::CallNamedFunctionExpression'
          function_ast_object = item
        else
          # Try and find the function with the AST tree
          distance_up_ast = -1
          function_ast_object = path[distance_up_ast]
          while !function_ast_object.nil? && function_ast_object.class.to_s != 'Puppet::Pops::Model::CallNamedFunctionExpression'
            distance_up_ast -= 1
            function_ast_object = path[distance_up_ast]
          end
          raise "Unable to find suitable parent object for object of type #{item.class}" if function_ast_object.nil?
        end

        function_name = function_ast_object.functor_expr.value
        raise 'Could not determine the function name' if function_name.nil?

        # Convert line and char nums (base 0) to an absolute offset within the document
        #   result.line_offsets contains an array of the offsets on a per line basis e.g.
        #     [0, 14, 34, 36]  means line number 2 starts at absolute offset 34
        #   Once we know the line offset, we can simply add on the char_num to get the absolute offset
        if function_ast_object.respond_to?(:locator)
          line_offset = function_ast_object.locator.line_index[line_num]
        else
          line_offset = locator.line_index[line_num]
        end

        abs_offset = line_offset + char_num
        # We need to use offsets here in case functions span lines
        param_number = param_number_from_ast(abs_offset, function_ast_object, locator)
        raise 'Cursor is not within the function expression' if param_number.nil?

        func_info = PuppetLanguageServer::PuppetHelper.function(function_name)
        raise "Function #{function_name} does not exist" if func_info.nil?

        func_info.signatures.each do |sig|
          lsp_sig = LSP::SignatureInformation.new.from_h!(
            'label'         => sig.key,
            'documentation' => sig.doc,
            'parameters'    => []
          )

          sig.parameters.each do |param|
            lsp_sig.parameters << LSP::ParameterInformation.new.from_h!(
              'label'         => param.signature_key_offset.nil? || param.signature_key_length.nil? ? param.name : [param.signature_key_offset, param.signature_key_offset + param.signature_key_length],
              'documentation' => param.doc
            )
          end

          response.signatures << lsp_sig
        end

        # Now figure out the first signature which could have the same or more than the number of arguments in the function call
        func_arg_count = function_ast_object.arguments.count
        signature_number = func_info.signatures.find_index { |sig| sig.parameters.count >= func_arg_count }

        # If we still don't know the signature number then assume it's the first one
        signature_number = 0 if signature_number.nil? && func_info.signatures.count > 0

        response.activeSignature = signature_number unless signature_number.nil?
        response.activeParameter = param_number

        response
      end

      def self.param_number_from_ast(char_offset, function_ast_object, locator)
        # Figuring out which parameter the cursor is in is a little tricky.  For example:
        #
        # func_two_param( $param1  ,  $param2  )
        # |------------------------------------|  Locator for the entire function
        # |-------------|                         Locator for the function expression
        #                 |-----|                 Locator for function.arguments[0] child (contains it's children)
        #                             |-----|     Locator for function.arguments[1] child (contains it's children)
        #
        # Importantly, whitespace isn't included in the AST

        function_offset     = function_ast_object.offset
        function_length     = function_ast_object.length
        functor_expr_offset = function_ast_object.functor_expr.offset
        functor_expr_length = function_ast_object.functor_expr.length

        # Shouldn't happen but, safety first!
        return nil if function_offset.nil? || function_length.nil? || functor_expr_offset.nil? || functor_expr_length.nil?

        # Is the cursor on the function name or the opening bracket? then we are not in any parameters
        return nil if char_offset <= functor_expr_offset + functor_expr_length
        # Is the cursor on or beyond the closing bracket? then we are not in any parameters
        return nil if char_offset >= function_offset + function_length
        # Does the function even have arguments? then the cursor HAS to be in the first parameter
        return 0 if function_ast_object.arguments.count.zero?
        # Is the cursor within any of the function argument locations? if so, return the parameter number we're in
        param_number = function_ast_object.arguments.find_index { |arg| char_offset >= arg.offset && char_offset <= arg.offset + arg.length }
        return param_number unless param_number.nil?

        # So now we know the char_offset exists outside any of the locators.  Check the extremities
        # Is it before the first argument? if so then the parameter number has to be zero
        return 0 if char_offset < function_ast_object.arguments[0].offset

        last_arg_index = function_ast_object.arguments.count - 1
        last_offset = function_ast_object.arguments[last_arg_index].offset + function_ast_object.arguments[last_arg_index].length
        if char_offset > last_offset
          # We know that the cursor is after the last argument, but before the closing bracket.
          # Therefore the before_index is the last argument in the list, and the after_index is one more than that
          before_index = last_arg_index
          after_index = last_arg_index + 1
          before_offset = function_ast_object.arguments[before_index].offset
          before_length = function_ast_object.arguments[before_index].length
          # But we need to get the text after the last argument, to the closing bracket
          locator_args = [
            last_offset,
            function_offset + function_length - last_offset - 1 # Find the difference from the entire function length and the last offset and subtract 1 for the closing bracket as we don't need it
          ]
        else
          # Now we now the char_offset exists between two existing locators.  Determine the location by finding which argument is AFTER the cursor
          after_index = function_ast_object.arguments.find_index { |arg| char_offset < arg.offset }
          return nil if after_index.nil? || after_index.zero? # This should never happen but, you never know.
          before_index = after_index - 1

          # Now we know between which arguments (before_index and after_index) the char_offset lies
          before_length = function_ast_object.arguments[before_index].length
          before_offset = function_ast_object.arguments[before_index].offset
          after_offset  = function_ast_object.arguments[after_index].offset

          # Determine the text between the two arguments
          locator_args = [
            before_offset + before_length,               # From the end the begin_index
            after_offset - before_offset - before_length # to the start of the after_index
          ]
        end
        between_text = function_ast_object.respond_to?(:locator) ? function_ast_object.locator.extract_text(*locator_args) : locator.extract_text(*locator_args)

        # Now we have the text between the two arguments, determine where the comma is
        comma_index = between_text.index(',')
        # If there is no comma then it has to be the before_index i.e.
        #   ..., $param   )   <--- the space before the closing bracket would have a between_text of '   '
        return before_index if comma_index.nil?

        # If the char_offset is after the comma then choose the after_index otherwise choose the before_index
        char_offset > before_offset + before_length + comma_index ? after_index : before_index
      end
      private_class_method :param_number_from_ast
    end
  end
end
