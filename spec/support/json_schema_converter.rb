# frozen_string_literal: true

require 'easy_talk'

class JsonSchemaConverter
  TYPE_MAPPING = {
    'string' => String,
    'integer' => Integer,
    'number' => Float,
    'boolean' => T::Boolean,
    'array' => T::Array[String]
  }.freeze

  CONSTRAINT_KEYS = {
    'minimum' => :minimum,
    'maximum' => :maximum,
    'minLength' => :min_length,
    'maxLength' => :max_length,
    'pattern' => :pattern,
    'enum' => :enum,
    'format' => :format
  }.freeze

  def initialize(schema, name = "TestModel_#{SecureRandom.hex(4)}")
    @schema = schema
    @name = name
  end

  def to_class
    schema_data = @schema
    model_name = @name
    converter = self

    Class.new do
      include EasyTalk::Model

      singleton_class.send(:define_method, :name) { model_name }

      define_schema do
        additional_properties converter.allows_additional_properties?(schema_data)

        title schema_data['title'] if schema_data['title']
        description schema_data['description'] if schema_data['description']

        schema_data['properties']&.each do |prop_name, prop_def|
          safe_prop_name = converter.sanitize_property_name(prop_name)
          type, constraints = converter.extract_type_and_constraints(prop_def)

          constraints[:as] = prop_name
          constraints[:optional] = true unless schema_data['required']&.include?(prop_name)

          property safe_prop_name.to_sym, type, **constraints
        end
      end
    end
  end

  def allows_additional_properties?(schema_data)
    !(schema_data.key?('additionalProperties') && schema_data['additionalProperties'] == false)
  end

  def sanitize_property_name(prop_name)
    safe_name = prop_name.to_s.gsub(/[^a-zA-Z0-9_]/, '_')
    safe_name = "prop_#{safe_name}" if safe_name.match?(/^\d/)
    safe_name = "prop_" if safe_name.empty?
    safe_name
  end

  def extract_type_and_constraints(prop_def)
    return [String, { optional: true }] if prop_def.is_a?(TrueClass) || prop_def.is_a?(FalseClass)
    return [String, {}] unless prop_def.is_a?(Hash)

    type = TYPE_MAPPING.fetch(prop_def['type'], String)
    constraints = extract_constraints(prop_def)

    [type, constraints]
  end

  def extract_constraints(prop_def)
    CONSTRAINT_KEYS.each_with_object({}) do |(json_key, ruby_key), constraints|
      constraints[ruby_key] = prop_def[json_key] if prop_def[json_key]
    end
  end
end
