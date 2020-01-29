# frozen_string_literal: true

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

      class ActionParams < Hash
        include Base

        def to_json(*options)
          ::JSON.generate(to_h, options)
        end

        def from_json!(json_string)
          obj = ::JSON.parse(json_string)
          obj.each do |key, value|
            self[key] = value
          end
          self
        end
      end

      class BaseClass
        include Base

        def to_json(*options)
          to_h.to_json(options)
        end

        def from_json!(json_string)
          from_h!(::JSON.parse(json_string))
        end

        def ==(other)
          return false unless other.class == self.class
          self.class
              .instance_methods(false)
              .reject { |name| name.to_s.end_with?('=') || name.to_s.end_with?('!') }
              .reject { |name| %i[to_h to_json].include?(name) }
              .each do |method_name|
            return false unless send(method_name) == other.send(method_name)
          end
          true
        end

        def eql?(other)
          return false unless other.class == self.class
          self.class
              .instance_methods(false)
              .reject { |name| name.to_s.end_with?('=') || name.to_s.end_with?('!') }
              .reject { |name| %i[to_h to_json].include?(name) }
              .each do |method_name|
            return false unless send(method_name).eql?(other.send(method_name))
          end
          true
        end

        def hash
          props = []
          self.class
              .instance_methods(false)
              .reject { |name| name.to_s.end_with?('=') || name.to_s.end_with?('!') }
              .reject { |name| %i[to_h to_json].include?(name) }
              .each do |method_name|
            props << send(method_name).hash
          end
          props.hash
        end
      end

      # key            => Unique name of the object
      # calling_source => The file that was invoked to create the object
      # source         => The file that _actually_ created the object
      # line           => The line number in the source file where the object was created
      # char           => The character number in the source file where the object was created
      # length         => The length of characters from `char` in the source file where the object was created
      class BasePuppetObject < BaseClass
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

        private

        def value_from_hash(hash, key)
          # The key could be a Symbol or String in the hash
          hash[key].nil? ? hash[key.to_s] : hash[key]
        end
      end

      class BasePuppetObjectList < Array
        include Base

        def to_json(*options)
          '[' + map { |item| item.to_json(options) }.join(',') + ']'
        end

        def from_json!(json_string)
          obj = ::JSON.parse(json_string)
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

      class NodeGraph < BaseClass
        attr_accessor :dot_content
        attr_accessor :error_content

        def to_json(*options)
          {
            'dot_content'   => dot_content,
            'error_content' => error_content
          }.to_json(options)
        end

        def from_json!(json_string)
          obj = ::JSON.parse(json_string)
          self.dot_content = obj['dot_content']
          self.error_content = obj['error_content']
          self
        end
      end

      class PuppetClass < BasePuppetObject
        attr_accessor :parameters
        attr_accessor :doc

        def to_h
          super.to_h.merge(
            'doc'        => doc,
            'parameters' => parameters
          )
        end

        def from_h!(value)
          super

          self.doc = value['doc']
          self.parameters = {}
          unless value['parameters'].nil?
            value['parameters'].each do |attr_name, obj_attr|
              # TODO: This should be a class, not a hash
              parameters[attr_name] = {
                :type => value_from_hash(obj_attr, :type),
                :doc  => value_from_hash(obj_attr, :doc)
              }
            end
          end
          self
        end
      end

      class PuppetClassList < BasePuppetObjectList
        def child_type
          PuppetClass
        end
      end

      class PuppetDataType < BasePuppetObject
        attr_accessor :doc
        attr_accessor :alias_of
        attr_accessor :attributes
        attr_accessor :is_type_alias

        def initialize
          super
          self.attributes = PuppetDataTypeAttributeList.new
        end

        def to_h
          super.to_h.merge(
            'doc'           => doc,
            'alias_of'      => alias_of,
            'attributes'    => attributes.map(&:to_h),
            'is_type_alias' => is_type_alias
          )
        end

        def from_h!(value)
          super

          self.doc = value['doc']
          self.alias_of = value['alias_of']
          value['attributes'].each { |attr| attributes << PuppetDataTypeAttribute.new.from_h!(attr) } unless value['attributes'].nil?
          self.is_type_alias = value['is_type_alias']
          self
        end
      end

      class PuppetDataTypeList < BasePuppetObjectList
        def child_type
          PuppetDataType
        end
      end

      class PuppetDataTypeAttribute < BaseClass
        attr_accessor :key
        attr_accessor :doc
        attr_accessor :default_value
        attr_accessor :types

        def to_h
          {
            'key'           => key,
            'default_value' => default_value,
            'doc'           => doc,
            'types'         => types
          }
        end

        def from_h!(value)
          self.key           = value['key']
          self.default_value = value['default_value']
          self.doc           = value['doc']
          self.types         = value['types']
          self
        end
      end

      class PuppetDataTypeAttributeList < BasePuppetObjectList
        def child_type
          PuppetDataTypeAttribute
        end
      end

      class PuppetFunction < BasePuppetObject
        attr_accessor :doc
        # The version of this function, typically 3 or 4.
        attr_accessor :function_version
        attr_accessor :signatures

        def initialize
          super
          self.signatures = PuppetFunctionSignatureList.new
        end

        def to_h
          super.to_h.merge(
            'doc'              => doc,
            'function_version' => function_version,
            'signatures'       => signatures.map(&:to_h)
          )
        end

        def from_h!(value)
          super

          self.doc = value['doc']
          self.function_version = value['function_version']
          value['signatures'].each { |sig| signatures << PuppetFunctionSignature.new.from_h!(sig) } unless value['signatures'].nil?
          self
        end
      end

      class PuppetFunctionList < BasePuppetObjectList
        def child_type
          PuppetFunction
        end
      end

      class PuppetFunctionSignature < BaseClass
        attr_accessor :key
        attr_accessor :doc
        attr_accessor :return_types
        attr_accessor :parameters

        def initialize
          super
          self.parameters = PuppetFunctionSignatureParameterList.new
        end

        def to_h
          {
            'key'          => key,
            'doc'          => doc,
            'return_types' => return_types,
            'parameters'   => parameters.map(&:to_h)
          }
        end

        def from_h!(value)
          self.key = value['key']
          self.doc = value['doc']
          self.return_types = value['return_types']
          value['parameters'].each { |param| parameters << PuppetFunctionSignatureParameter.new.from_h!(param) } unless value['parameters'].nil?
          self
        end
      end

      class PuppetFunctionSignatureList < BasePuppetObjectList
        def child_type
          PuppetFunctionSignature
        end
      end

      class PuppetFunctionSignatureParameter < BaseClass
        attr_accessor :name
        attr_accessor :types
        attr_accessor :doc
        attr_accessor :signature_key_offset # Zero based offset where this parameter exists in the signature key
        attr_accessor :signature_key_length # The length of text where this parameter exists in the signature key

        def to_h
          {
            'name'                 => name,
            'doc'                  => doc,
            'types'                => types,
            'signature_key_offset' => signature_key_offset,
            'signature_key_length' => signature_key_length
          }
        end

        def from_h!(value)
          self.name = value['name']
          self.doc = value['doc']
          self.types = value['types']
          self.signature_key_offset = value['signature_key_offset']
          self.signature_key_length = value['signature_key_length']
          self
        end
      end

      class PuppetFunctionSignatureParameterList < BasePuppetObjectList
        def child_type
          PuppetFunctionSignatureParameter
        end
      end

      class PuppetType < BasePuppetObject
        attr_accessor :doc
        attr_accessor :attributes

        def to_h
          super.to_h.merge(
            'doc'        => doc,
            'attributes' => attributes
          )
        end

        def from_h!(value)
          super

          self.doc = value['doc']
          self.attributes = {}
          unless value['attributes'].nil?
            value['attributes'].each do |attr_name, obj_attr|
              attributes[attr_name.intern] = {
                # TODO: This should be a class, not a hash
                :type       => value_from_hash(obj_attr, :type).intern,
                :doc        => value_from_hash(obj_attr, :doc),
                :required?  => value_from_hash(obj_attr, :required?),
                :isnamevar? => value_from_hash(obj_attr, :isnamevar?)
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

      class Resource < BaseClass
        attr_accessor :manifest

        def to_h
          {
            'manifest' => manifest
          }
        end

        def from_h!(value)
          self.manifest = value['manifest']
          self
        end

        def to_json(*options)
          to_h.to_json(options)
        end

        def from_json!(json_string)
          from_h!(::JSON.parse(json_string))
        end
      end

      class ResourceList < BasePuppetObjectList
        def child_type
          Resource
        end
      end

      # This class is a little special as it contains a lot logic.
      # In essence this is just wrapping a hash with specific methods for the
      # the different types of metadata (classes, functions etc.)
      class AggregateMetadata < BaseClass
        def initialize
          super
          @aggregate = {}
        end

        def classes
          @aggregate[:classes]
        end

        def datatypes
          @aggregate[:datatypes]
        end

        def functions
          @aggregate[:functions]
        end

        def types
          @aggregate[:types]
        end

        def concat!(array)
          return if array.nil? || array.empty?
          array.each { |item| append!(item) }
        end

        def append!(obj)
          list_for_object_class(obj.class) << obj
        end

        def to_json(*options)
          @aggregate.to_json(options)
        end

        def from_json!(json_string)
          obj = ::JSON.parse(json_string)
          obj.each do |key, value|
            info = METADATA_LIST[key.intern]
            next if info.nil?
            list = list_for_object_class(info[:item_class])
            value.each { |i| list << info[:item_class].new.from_h!(i) }
          end
          self
        end

        def each_list
          return unless block_given?
          @aggregate.each { |k, v| yield k, v }
        end

        private

        # When adding a new metadata item:
        # - Add to the information to this hash
        # - Add a method to access the aggregate
        METADATA_LIST = {
          :classes   => {
            :item_class => PuppetClass,
            :list_class => PuppetClassList
          },
          :datatypes => {
            :item_class => PuppetDataType,
            :list_class => PuppetDataTypeList
          },
          :functions => {
            :item_class => PuppetFunction,
            :list_class => PuppetFunctionList
          },
          :types     => {
            :item_class => PuppetType,
            :list_class => PuppetTypeList
          }
        }.freeze

        def list_for_object_class(klass)
          METADATA_LIST.each do |name, info|
            if klass == info[:item_class]
              @aggregate[name] = info[:list_class].new if @aggregate[name].nil?
              return @aggregate[name]
            end
          end

          raise "Unknown object class #{klass.name}"
        end
      end

      class Fact < BasePuppetObject
        attr_accessor :value

        def to_h
          super.to_h.merge(
            'value' => value
          )
        end

        def from_h!(value)
          super

          self.value = value['value']
          self
        end
      end

      class FactList < BasePuppetObjectList
        def child_type
          Fact
        end
      end
    end
  end
end
