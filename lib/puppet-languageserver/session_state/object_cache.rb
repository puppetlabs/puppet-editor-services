# frozen_string_literal: true

module PuppetLanguageServer
  module SessionState
    class ObjectCache
      SECTIONS = %i[class type function datatype fact].freeze
      ORIGINS = %i[default workspace bolt].freeze

      def initialize(_options = {})
        @cache_lock = Mutex.new
        @inmemory_cache = {}
        # The cache consists of hash of hashes
        # @inmemory_cache[<origin>][<section>] = [ Array of SidecarProtocol Objects ]
      end

      def import_sidecar_list!(list, section, origin)
        return if origin.nil?
        return if section.nil?

        list = [] if list.nil?

        @cache_lock.synchronize do
          # Remove the existing items
          remove_section_impl(section, origin)
          # Set the list
          @inmemory_cache[origin] = {} if @inmemory_cache[origin].nil?
          @inmemory_cache[origin][section] = list.dup
        end
        nil
      end

      def remove_section!(section, origin = nil)
        @cache_lock.synchronize do
          remove_section_impl(section, origin)
        end
        nil
      end

      def remove_origin!(origin)
        @cache_lock.synchronize do
          @inmemory_cache[origin] = nil
        end
        nil
      end

      def origin_exist?(origin)
        @cache_lock.synchronize do
          return @inmemory_cache.key?(origin)
        end
      end

      def section_in_origin_exist?(section, origin)
        @cache_lock.synchronize do
          return false if @inmemory_cache[origin].nil? || @inmemory_cache[origin].empty?

          @inmemory_cache[origin].key?(section)
        end
      end

      # section => <Type of object in the file :function, :type, :class, :datatype>
      def object_by_name(section, name, options = {})
        # options[:exclude_origins]
        # options[:fuzzy_match]
        options = {
          exclude_origins: [],
          fuzzy_match: false
        }.merge(options)

        name = name.intern if name.is_a?(String)
        return nil if section.nil?

        @cache_lock.synchronize do
          @inmemory_cache.each do |origin, sections|
            next if sections.nil? || sections[section].nil? || sections[section].empty?
            next if options[:exclude_origins].include?(origin)

            sections[section].each do |item|
              match = options[:fuzzy_match] ? fuzzy_match?(item.key, name) : item.key == name
              return item if match
            end
          end
        end
        nil
      end

      # Performs fuzzy text matching of Puppet Language Type names
      #  e.g 'TargetSpec' in 'Boltlib::TargetSpec'
      # @api private
      def fuzzy_match?(obj, test_obj)
        value = obj.is_a?(String) ? obj.dup : obj.to_s
        test_string = test_obj.is_a?(String) ? test_obj.dup : test_obj.to_s

        # Test for equality
        return true if value == test_string

        # Test for a shortname
        if !test_string.start_with?('::') && value.end_with?("::#{test_string}")
          # e.g 'TargetSpec' in 'Boltlib::TargetSpec'
          return true
        end

        false
      end

      # section => <Type of object in the file :function, :type, :class, :datatype>
      # options[:exclude_origins]
      def object_names_by_section(section, options = {})
        options = {
          exclude_origins: []
        }.merge(options)
        result = []
        return result if section.nil?

        @cache_lock.synchronize do
          @inmemory_cache.each do |origin, sections|
            next if sections.nil? || sections[section].nil? || sections[section].empty?
            next if options[:exclude_origins].include?(origin)

            result.concat(sections[section].map { |i| i.key })
          end
        end
        result.uniq!
        result.compact
      end

      # section => <Type of object in the file :function, :type, :class, :datatype>
      def objects_by_section(section, &_block)
        return if section.nil?

        @cache_lock.synchronize do
          @inmemory_cache.each_value do |sections|
            next if sections.nil? || sections[section].nil? || sections[section].empty?

            sections[section].each { |i| yield i.key, i }
          end
        end
      end

      def all_objects(&_block)
        @cache_lock.synchronize do
          @inmemory_cache.each_value do |sections|
            next if sections.nil?

            sections.each_value do |list|
              list.each { |i| yield i.key, i }
            end
          end
        end
      end

      private

      def remove_section_impl(section, origin = nil)
        @inmemory_cache.each do |list_origin, sections|
          next unless origin.nil? || list_origin == origin

          sections[section].clear unless sections.nil? || sections[section].nil?
        end
      end
    end
  end
end
