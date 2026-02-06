# frozen_string_literal: true
# typed: true

require "active_model"
require "active_support/json"

module EasyTalk
  # ActiveModel::Type adapter for EasyTalk schema/model classes.
  #
  # Usage:
  #   attribute :settings, ConversationSettings::SpaceSettings.to_type
  #
  # This replaces `serialize ... coder:` while keeping EasyTalk as the schema
  # source of truth. Casting is best-effort for primitive types, arrays, tuples,
  # and nested EasyTalk models.
  class ActiveModelType < ActiveModel::Type::Value
    def initialize(schema_class)
      @schema_class = schema_class
      super()
    end

    def type
      :json
    end

    def cast(value)
      cast_value(value)
    end

    def deserialize(value)
      cast_value(value)
    end

    def serialize(value)
      case value
      when nil
        nil
      when @schema_class
        value.to_h
      when Hash
        value
      else
        value.respond_to?(:to_h) ? value.to_h : value
      end
    end

    def changed_in_place?(raw_old_value, new_value)
      normalize_for_comparison(cast_value(raw_old_value)) != normalize_for_comparison(new_value)
    end

    private

    # ActiveRecord calls `changed_in_place?` with the raw DB value and the current
    # (type-cast) value to detect in-place mutations of mutable attributes.
    #
    # EasyTalk schema/model instances only implement `==` against Hashes (and
    # otherwise fall back to object identity). If we compare instances directly,
    # two distinct instances with identical data will always be treated as
    # different, causing "always dirty" attributes.
    #
    # To avoid that, compare a deep, JSON-ready representation instead.
    def normalize_for_comparison(value)
      value = serialize(value) if easy_talk_model_class?(value.class)

      case value
      when Hash
        value.each_with_object({}) do |(k, v), out|
          out[k.to_s] = normalize_for_comparison(v)
        end
      when Array
        value.map { |item| normalize_for_comparison(item) }
      else
        value
      end
    end

    def cast_value(value)
      case value
      when nil
        nil
      when @schema_class
        value
      when String
        build_instance(decode_json(value))
      when Hash
        build_instance(value)
      else
        value.respond_to?(:to_h) ? build_instance(value.to_h) : value
      end
    end

    def decode_json(value)
      ActiveSupport::JSON.decode(value)
    rescue JSON::ParserError, TypeError
      {}
    end

    def build_instance(value)
      return value if value.is_a?(@schema_class)
      return @schema_class.new(cast_attributes(value)) if value.is_a?(Hash)

      @schema_class.new({})
    end

    def cast_attributes(raw, schema_class: @schema_class)
      return raw unless raw.is_a?(Hash)

      schema = schema_definition_for(schema_class)
      return raw unless schema.is_a?(Hash)

      properties = schema[:properties] || {}
      return raw if properties.empty?

      casted = raw.dup
      properties.each do |prop_name, prop_def|
        next unless prop_def.is_a?(Hash)

        key, raw_value = fetch_key(casted, prop_name)
        next if key.nil?

        casted[key] = cast_property_value(prop_def[:type], raw_value)
      end

      casted
    end

    def fetch_key(hash, prop_name)
      return [prop_name, hash[prop_name]] if hash.key?(prop_name)

      string_key = prop_name.to_s
      return [string_key, hash[string_key]] if hash.key?(string_key)

      [nil, nil]
    end

    def cast_property_value(type, value)
      return nil if value.nil?

      unwrapped_type = unwrap_nilable(type)

      return cast_array_value(unwrapped_type, value) if unwrapped_type.is_a?(T::Types::TypedArray)

      return cast_tuple_value(unwrapped_type, value) if unwrapped_type.is_a?(EasyTalk::Types::Tuple)

      type_class = resolve_type_class(unwrapped_type)
      if easy_talk_model_class?(type_class)
        return type_class.new(cast_attributes(value, schema_class: type_class)) if value.is_a?(Hash)
        return value if value.is_a?(type_class)
      end

      cast_primitive(unwrapped_type, value, type_class: type_class)
    end

    def cast_array_value(type, value)
      return value unless value.is_a?(Array)

      element_type = type.type
      value.map { |item| cast_property_value(element_type, item) }
    end

    def cast_tuple_value(type, value)
      return value unless value.is_a?(Array)

      value.each_with_index.map do |item, index|
        element_type = type.types[index] || type.types.last
        cast_property_value(element_type, item)
      end
    end

    def cast_primitive(type, value, type_class: nil)
      return ActiveModel::Type::Boolean.new.cast(value) if TypeIntrospection.boolean_type?(type)

      type_class ||= resolve_type_class(type)
      return value unless type_class

      case type_class.name
      when "Integer"
        ActiveModel::Type::Integer.new.cast(value)
      when "Float"
        ActiveModel::Type::Float.new.cast(value)
      when "BigDecimal"
        ActiveModel::Type::Decimal.new.cast(value)
      when "String"
        ActiveModel::Type::String.new.cast(value)
      else
        value
      end
    end

    def resolve_type_class(type)
      return type if type.is_a?(Class)
      return type.raw_type if type.respond_to?(:raw_type)

      nil
    end

    def easy_talk_model_class?(type)
      type.is_a?(Class) && (type.include?(EasyTalk::Model) || type.include?(EasyTalk::Schema))
    end

    def unwrap_nilable(type)
      return type unless type.respond_to?(:nilable?) && type.nilable?

      T::Utils::Nilable.get_underlying_type(type)
    end

    def schema_definition_for(schema_class)
      return unless schema_class.respond_to?(:schema_definition)

      schema_class.schema_definition&.schema
    end
  end
end
