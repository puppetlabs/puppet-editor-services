module PuppetLanguageServer
  module PuppetHelper
    # key            => Unique name of the object
    # calling_source => The file that was invoked to create the object
    # source         => The file that _actually_ created the object
    # line           => The line number in the source file where the object was created
    # char           => The character number in the source file where the object was created
    # length         => The length of characters from `char` in the source file where the object was created
    class BasePuppetObject
      attr_accessor :key
      attr_accessor :calling_source
      attr_accessor :source
      attr_accessor :line
      attr_accessor :char
      attr_accessor :length
      attr_accessor :origin

      def from_sidecar!(value)
        @key = value.key
        @calling_source = value.calling_source
        @source = value.source
        @line = value.line
        @char = value.char
        @length = value.length
        self
      end
    end

    class PuppetClass < BasePuppetObject
      attr_accessor :doc
      attr_accessor :parameters

      def from_sidecar!(value)
        super
        @doc = value.doc
        @parameters = value.parameters
        self
      end
    end

    class PuppetFunction < BasePuppetObject
      attr_accessor :doc
      attr_accessor :arity
      attr_accessor :type

      def from_sidecar!(value)
        super
        @doc = value.doc
        @arity = value.arity
        @type = value.type
        self
      end
    end

    class PuppetType < BasePuppetObject
      attr_accessor :doc
      attr_accessor :attributes

      def allattrs
        @attributes.keys
      end

      def parameters
        @attributes.select { |_name, data| data[:type] == :param }
      end

      def properties
        @attributes.select { |_name, data| data[:type] == :property }
      end

      def meta_parameters
        @attributes.select { |_name, data| data[:type] == :meta }
      end

      def from_sidecar!(value)
        super
        @doc = value.doc
        @attributes = value.attributes
        self
      end
    end
  end
end
