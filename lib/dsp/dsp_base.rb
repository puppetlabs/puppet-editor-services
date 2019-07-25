# frozen_string_literal: true

require 'json'

module DSP
  class DSPBase
    def initialize(initial_hash = nil)
      from_h!(initial_hash) unless initial_hash.nil?
    end

    def to_h
      value = {}
      optional_names = @optional_method_names.nil? ? [] : @optional_method_names

      instance_method_names.each do |name|
        item_value = send(name)
        if item_value.is_a?(Array)
          # Convert the items in the array .to_h
          item_value = item_value.map { |item| item.to_h }
        elsif !item_value.nil? && item_value.respond_to?(:to_h)
          item_value = item_value.to_h
        end
        value[name.to_s] = item_value unless optional_names.include?(name) && item_value.nil?
      end

      value
    end

    def from_h!(value)
    end

    def to_json(*options)
      to_h.to_json(options)
    end

    private

    def instance_method_names
      method_names = methods - DSP::DSPBase.instance_methods

      method_names.reject { |name| name.to_s.end_with?('=') }
    end

    def to_typed_aray(val, expected_type)
      return nil if val.nil?

      val.map { |item| expected_type.new(item) }
    end
  end

  def self.create_range(from_line, from_char, to_line, to_char)
    {
      'start' => {
        'line'      => from_line,
        'character' => from_char
      },
      'end'   => {
        'line'      => to_line,
        'character' => to_char
      }
    }
  end
end
