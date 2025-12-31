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
    # String constraints
    'minLength' => :min_length,
    'maxLength' => :max_length,
    'pattern' => :pattern,
    'format' => :format,
    # Numeric constraints
    'minimum' => :minimum,
    'maximum' => :maximum,
    'exclusiveMinimum' => :exclusive_minimum,
    'exclusiveMaximum' => :exclusive_maximum,
    'multipleOf' => :multiple_of,
    # Array constraints
    'minItems' => :min_items,
    'maxItems' => :max_items,
    'uniqueItems' => :unique_items,
    # Common constraints
    'enum' => :enum,
    'const' => :const,
    'default' => :default
  }.freeze

  def initialize(schema, name = "TestModel_#{SecureRandom.hex(4)}")
    @schema = schema
    @name = name
  end

  # Check if this schema needs to be wrapped (i.e., it's not an object schema)
  def needs_wrapping?
    return false if @schema.is_a?(TrueClass) || @schema.is_a?(FalseClass)
    return true unless @schema.is_a?(Hash)

    # If schema has explicit type: object, no wrapping needed
    return false if @schema['type'] == 'object'

    # If schema has properties, treat as object schema
    return false if @schema.key?('properties')

    # Everything else needs wrapping (primitives, arrays, schemas with only constraints)
    true
  end

  # Wrap test data for schemas that were wrapped
  def wrap_data(data)
    { 'value' => data }
  end

  def to_class
    schema_data = @schema
    model_name = @name

    if needs_wrapping?
      build_wrapped_class(schema_data, model_name)
    else
      build_object_class(schema_data, model_name)
    end
  end

  private

  def build_wrapped_class(schema_data, model_name)
    converter = self

    Class.new do
      include EasyTalk::Model

      singleton_class.send(:define_method, :name) { model_name }

      define_schema do
        # The entire original schema becomes constraints on the 'value' property
        type, constraints = converter.extract_type_and_constraints(schema_data)
        property :value, type, **constraints
      end
    end
  end

  def build_object_class(schema_data, model_name)
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

  public

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

    type = determine_type(prop_def)
    constraints = extract_constraints(prop_def)

    [type, constraints]
  end

  def determine_type(prop_def)
    type_value = prop_def['type']

    # Handle array of types (e.g., ["string", "null"])
    if type_value.is_a?(Array)
      non_null_types = type_value - ['null']
      is_nullable = type_value.include?('null')

      base_type = resolve_single_type(non_null_types.first, prop_def)
      return is_nullable ? T.nilable(base_type) : base_type
    end

    # Handle single type
    resolve_single_type(type_value, prop_def)
  end

  def resolve_single_type(type_name, prop_def)
    case type_name
    when 'array'
      determine_array_type(prop_def)
    when 'string'
      String
    when 'integer'
      Integer
    when 'number'
      Float
    when 'boolean'
      T::Boolean
    when 'null'
      NilClass
    else
      String
    end
  end

  def determine_array_type(prop_def)
    items_schema = prop_def['items']
    return T::Array[String] unless items_schema.is_a?(Hash)

    item_type = TYPE_MAPPING.fetch(items_schema['type'], String)
    T::Array[item_type]
  end

  def extract_constraints(prop_def)
    CONSTRAINT_KEYS.each_with_object({}) do |(json_key, ruby_key), constraints|
      constraints[ruby_key] = prop_def[json_key] if prop_def.key?(json_key)
    end
  end
end
