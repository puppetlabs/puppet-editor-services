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
        # TODO: name ?
        obj.doc   = item[:doc]
        obj.arity = item[:arity]
        obj.type  = item[:type]
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
