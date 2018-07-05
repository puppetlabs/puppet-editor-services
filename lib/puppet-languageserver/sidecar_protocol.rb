module PuppetLanguageServer
  module Sidecar
    module Protocol
      module Base
        def to_json(*_options)
          raise NotImplementedError
        end

        def from_json!(_json_string)
          raise NotImplementedError
        end
      end

      # key            => Unique name of the object
      # calling_source => The file that was invoked to create the object
      # source         => The file that _actually_ created the object
      # line           => The line number in the source file where the object was created
      # char           => The character number in the source file where the object was created
      # length         => The length of characters from `char` in the source file where the object was created
      class BasePuppetObject
        include Base
        attr_accessor :key
        attr_accessor :calling_source
        attr_accessor :source
        attr_accessor :line
        attr_accessor :char
        attr_accessor :length

        def to_h
          {
            'key'            => key,
            'calling_source' => calling_source,
            'source'         => source,
            'line'           => line,
            'char'           => char,
            'length'         => length
          }
        end

        def from_h!(value)
          self.key            = value['key'].nil? ? nil : value['key'].intern
          self.calling_source = value['calling_source']
          self.source         = value['source']
          self.line           = value['line']
          self.char           = value['char']
          self.length         = value['length']
          self
        end

        def to_json(*options)
          to_h.to_json(options)
        end

        def from_json!(json_string)
          from_h!(JSON.parse(json_string))
        end
      end

      class BasePuppetObjectList < Array
        include Base

        def to_json(*options)
          '[' + map { |item| item.to_json(options) }.join(',') + ']'
        end

        def from_json!(json_string)
          obj = JSON.parse(json_string)
          obj.each do |child_hash|
            child = child_type.new
            self << child.from_h!(child_hash)
          end
          self
        end

        def child_type
          Object
        end
      end

      class PuppetClass < BasePuppetObject
        # TODO: Doc, parameters?
      end

      class PuppetClassList < BasePuppetObjectList
        def child_type
          PuppetClass
        end
      end

      class PuppetFunction < BasePuppetObject
        attr_accessor :doc
        attr_accessor :arity
        attr_accessor :type

        def to_h
          super.to_h.merge(
            'doc'            => doc,
            'arity'          => arity,
            'type'           => type
          )
        end

        def from_h!(value)
          super

          self.doc = value['doc']
          self.arity = value['arity']
          self.type = value['type'].intern
          self
        end
      end

      class PuppetFunctionList < BasePuppetObjectList
        def child_type
          PuppetFunction
        end
      end

      class PuppetType < BasePuppetObject
        attr_accessor :doc
        attr_accessor :attributes

        def to_h
          super.to_h.merge(
            'key'            => key,
            'calling_source' => calling_source,
            'source'         => source,
            'line'           => line,
            'char'           => char,
            'length'         => length,

            'doc'            => doc,
            'attributes'     => attributes
          )
        end

        def from_h!(value)
          super

          self.doc = value['doc']
          self.attributes = {}
          unless value['attributes'].nil?
            value['attributes'].each do |attr_name, obj_attr|
              attributes[attr_name.intern] = {
                :type      => obj_attr['type'].intern,
                :doc       => obj_attr['doc'],
                :required? => obj_attr['required?']
              }
            end
          end
          self
        end
      end

      class PuppetTypeList < BasePuppetObjectList
        def child_type
          PuppetType
        end
      end
    end
  end
end
