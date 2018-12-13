module PuppetLanguageServer
  module PuppetHelper
    class Cache
      def initialize(_options = {})
        @cache_lock = Mutex.new
        @inmemory_cache = []
        # The cache consists of an array of module PuppetLanguageServer::PuppetHelper objects
      end

      def import_sidecar_list!(list, section, origin = nil)
        section_object = section_to_object(section)
        return if section_object.nil?

        @cache_lock.synchronize do
          # Remove the existing items
          @inmemory_cache.reject! { |item| item.is_a?(section_object) && (origin.nil? || item.origin == origin) }
          # Append the list
          list.each do |item|
            object = sidecar_protocol_to_cache_object(item)
            object.origin = origin
            @inmemory_cache << object
          end
        end
        nil
      end

      def remove_section!(section, origin = nil)
        section_object = section_to_object(section)
        return if section_object.nil?

        @cache_lock.synchronize do
          @inmemory_cache.reject! { |item| item.is_a?(section_object) && (origin.nil? || item.origin == origin) }
        end
        nil
      end

      # section => <Type of object in the file :function, :type, :class>
      def object_by_name(section, name)
        name = name.intern if name.is_a?(String)
        section_object = section_to_object(section)
        return nil if section_object.nil?
        @cache_lock.synchronize do
          @inmemory_cache.each do |item|
            next unless item.is_a?(section_object) && item.key == name
            return item
          end
        end
        nil
      end

      # section => <Type of object in the file :function, :type, :class>
      def object_names_by_section(section)
        result = []
        section_object = section_to_object(section)
        return result if section_object.nil?
        @cache_lock.synchronize do
          @inmemory_cache.each do |item|
            next unless item.is_a?(section_object)
            result << item.key
          end
        end
        result.uniq!
        result.compact
      end

      # section => <Type of object in the file :function, :type, :class>
      def objects_by_section(section, &_block)
        section_object = section_to_object(section)
        return if section_object.nil?
        @cache_lock.synchronize do
          @inmemory_cache.each do |item|
            next unless item.is_a?(section_object)
            yield item.key, item
          end
        end
      end

      def all_objects(&_block)
        @cache_lock.synchronize do
          @inmemory_cache.each do |item|
            yield item.key, item
          end
        end
      end

      private

      # <Type of object in the file :function, :type, :class>
      def section_to_object(section)
        case section
        when :class
          PuppetLanguageServer::PuppetHelper::PuppetClass
        when :function
          PuppetLanguageServer::PuppetHelper::PuppetFunction
        when :type
          PuppetLanguageServer::PuppetHelper::PuppetType
        end
      end

      def sidecar_protocol_to_cache_object(value)
        return PuppetLanguageServer::PuppetHelper::PuppetClass.new.from_sidecar!(value) if value.is_a?(PuppetLanguageServer::Sidecar::Protocol::PuppetClass)
        return PuppetLanguageServer::PuppetHelper::PuppetFunction.new.from_sidecar!(value) if value.is_a?(PuppetLanguageServer::Sidecar::Protocol::PuppetFunction)
        return PuppetLanguageServer::PuppetHelper::PuppetType.new.from_sidecar!(value) if value.is_a?(PuppetLanguageServer::Sidecar::Protocol::PuppetType)
        nil
      end
    end
  end
end
