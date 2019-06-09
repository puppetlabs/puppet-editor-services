# frozen_string_literal: true

require 'puppet-languageserver/sidecar_protocol'

module PuppetLanguageServerSidecar
  module Protocol
    class NodeGraph < PuppetLanguageServer::Sidecar::Protocol::NodeGraph
      def set_error(message) # rubocop:disable Naming/AccessorMethodName
        self.error_content = message
        self.dot_content = ''
        self
      end
    end

    class PuppetClass < PuppetLanguageServer::Sidecar::Protocol::PuppetClass
      def self.from_puppet(name, item, locator)
        name = name.intern if name.is_a?(String)
        obj = PuppetLanguageServer::Sidecar::Protocol::PuppetClass.new
        obj.key            = name
        obj.doc            = item['doc']
        obj.source         = item['source']
        obj.calling_source = obj.source
        obj.line           = item['line']
        obj.char           = item['char']
        obj.parameters     = {}
        item['parameters'].each do |param|
          val = {
            :type => nil,
            :doc  => nil
          }
          val[:type] = locator.extract_text(param.type_expr.offset, param.type_expr.length) unless param.type_expr.nil?
          # TODO: Need to learn how to read the help/docs for hover support
          obj.parameters[param.name] = val
        end
        obj
      end
    end

    class PuppetFunction < PuppetLanguageServer::Sidecar::Protocol::PuppetFunction
      def self.from_puppet(name, item)
        obj = PuppetLanguageServer::Sidecar::Protocol::PuppetFunction.new
        obj.key            = name
        obj.source         = item[:source_location][:source]
        obj.calling_source = obj.source
        obj.line           = item[:source_location][:line]
        # This method is only called for V3 API functions. Therefore we need to transform this V3 function into V4 metadata
        obj.doc = 'This uses the legacy Ruby function API'
        obj.doc += "\n\n" + item[:doc] unless item[:doc].nil?
        obj.function_version = 3

        # V3 functions don't explicitly define signatures.  We can craft an approximation using arity
        # From - https://github.com/puppetlabs/puppet/blob/904023ffc59bc6771c0c7abf2a1d2c4acf941b09/lib/puppet/parser/functions.rb#L159-L168
        #
        # @option options [Integer] :arity (-1) the
        #   [arity](https://en.wikipedia.org/wiki/Arity) of the function.  When
        #   specified as a positive integer the function is expected to receive
        #   _exactly_ the specified number of arguments.  When specified as a
        #   negative number, the function is expected to receive _at least_ the
        #   absolute value of the specified number of arguments incremented by one.
        #   For example, a function with an arity of `-4` is expected to receive at
        #   minimum 3 arguments.  A function with the default arity of `-1` accepts
        #   zero or more arguments.  A function with an arity of 2 must be provided
        #   with exactly two arguments, no more and no less.  Added in Puppet 3.1.0.
        #
        # Find the number of required parameters
        sig_params = []
        param_text = []
        required_params = item[:arity] < 0 ? -item[:arity] - 1 : item[:arity]
        (1..required_params).each do |index|
          sig_params << {
            'name'  => "param#{index}",
            'types' => ['Any']
          }
          param_text << "Any $param#{index}"
        end
        # Add optional parameters if needed
        if item[:arity] < 0
          sig_params << {
            'name'  => '*args',
            'types' => ['Optional[Any]']
          }
          param_text << 'Optional[Any] *args'
        end

        # V3 functions only have a single signature
        obj.signatures << PuppetLanguageServer::Sidecar::Protocol::PuppetFunctionSignature.new.from_h!(
          'key'          => "#{name}(#{param_text.join(', ')})",
          'doc'          => item[:doc],
          'parameters'   => sig_params,
          'return_types' => item[:type] == :rvalue ? ['Any'] : ['Undef'] # :rvalue type functions return something. :statement type functions don't return anything so Undef
        )
        obj
      end
    end

    class PuppetType < PuppetLanguageServer::Sidecar::Protocol::PuppetType
      def self.from_puppet(name, item)
        name = name.intern if name.is_a?(String)
        obj = PuppetLanguageServer::Sidecar::Protocol::PuppetType.new
        obj.key            = name
        obj.source         = item._source_location[:source]
        obj.calling_source = obj.source
        obj.line           = item._source_location[:line]
        obj.doc            = item.doc
        obj.attributes = {}
        item.allattrs.each do |attrname|
          attrclass = item.attrclass(attrname)
          val = {
            :type => item.attrtype(attrname),
            :doc  => attrclass.doc
          }
          val[:required?] = attrclass.required? if attrclass.respond_to?(:required?)
          val[:isnamevar?] = attrclass.required? if attrclass.respond_to?(:isnamevar?)
          obj.attributes[attrname] = val
        end
        obj
      end
    end
  end
end
