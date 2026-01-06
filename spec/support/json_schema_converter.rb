# frozen_string_literal: true

require 'easy_talk'

class JsonSchemaConverter
  TYPE_MAPPING = {
    'string' => String,
    'integer' => Integer,
    'number' => Float,
    'boolean' => T::Boolean,
    'array' => Array  # Untyped array - item type determined by determine_array_type
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
    'additionalItems' => :additional_items,
    # Common constraints
    'enum' => :enum,
    'const' => :const,
    'default' => :default
  }.freeze

  # Array-specific JSON Schema keywords that imply the schema is for arrays
  # Includes keywords from Draft 7 through Draft 2020-12 for forward compatibility
  # Using Set for O(1) membership lookups
  ARRAY_CONSTRAINT_KEYS = Set.new(%w[
                                    minItems maxItems uniqueItems items additionalItems contains
                                    minContains maxContains prefixItems unevaluatedItems
                                  ]).freeze

  # Object-level constraint keys (apply to the object as a whole, not properties)
  OBJECT_CONSTRAINT_KEYS = {
    'minProperties' => :min_properties,
    'maxProperties' => :max_properties,
    'dependentRequired' => :dependent_required
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

    # If schema has object-level constraints (minProperties, maxProperties, etc.),
    # treat as object schema - these constraints apply to objects only
    return false if has_object_constraints?

    # Everything else needs wrapping (primitives, arrays, schemas with only constraints)
    true
  end

  # Check if schema is an object-constraint-only schema (no properties defined)
  # These schemas validate any object based on property count or dependencies
  def object_constraint_only_schema?
    return false unless @schema.is_a?(Hash)
    return false if @schema.key?('properties')
    return false if @schema['type'] && @schema['type'] != 'object'

    has_object_constraints?
  end

  # Check if the schema has object-level constraints
  def has_object_constraints?
    return false unless @schema.is_a?(Hash)

    OBJECT_CONSTRAINT_KEYS.keys.any? { |key| @schema.key?(key) }
  end

  # Wrap test data for schemas that were wrapped
  def wrap_data(data)
    { 'value' => data }
  end

  def to_class(property_names: nil)
    schema_data = @schema
    model_name = @name

    if needs_wrapping?
      build_wrapped_class(schema_data, model_name)
    elsif object_constraint_only_schema? && property_names
      # For schemas with only object-level constraints, dynamically create properties from test data
      build_dynamic_object_class(schema_data, model_name, property_names)
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

        # Apply object-level constraints
        converter.extract_object_constraints(schema_data).each do |constraint_name, constraint_value|
          send(constraint_name, constraint_value)
        end

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

  # Build a class for object-constraint-only schemas with dynamic properties
  # These schemas have minProperties/maxProperties but no defined properties
  def build_dynamic_object_class(schema_data, model_name, property_names)
    converter = self

    Class.new do
      include EasyTalk::Model

      singleton_class.send(:define_method, :name) { model_name }

      define_schema do
        additional_properties true

        # Apply object-level constraints
        converter.extract_object_constraints(schema_data).each do |constraint_name, constraint_value|
          send(constraint_name, constraint_value)
        end

        # Define properties dynamically based on test data keys
        # All properties are optional since they come from dynamic test data
        property_names.each do |prop_name|
          safe_prop_name = converter.sanitize_property_name(prop_name.to_s)
          property safe_prop_name.to_sym, T.nilable(T.untyped), optional: true, as: prop_name.to_s
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

    # If no explicit type but has array constraints, infer array type
    return determine_array_type(prop_def) if type_value.nil? && has_array_constraints?(prop_def)

    # Handle single type
    resolve_single_type(type_value, prop_def)
  end

  def has_array_constraints?(prop_def)
    ARRAY_CONSTRAINT_KEYS.intersect?(prop_def.keys)
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

    # Handle tuple-style items (array of schemas)
    # Return untyped Array - tuple constraints are handled separately
    return Array if items_schema.is_a?(Array)

    # Use untyped Array when no items schema is specified (JSON Schema allows any items)
    return Array unless items_schema.is_a?(Hash)

    # Empty schema {} means any type is valid - use untyped Array
    return Array unless items_schema.key?('type')

    item_type = TYPE_MAPPING.fetch(items_schema['type'], String)
    T::Array[item_type]
  end

  # Extract tuple items constraint from array schema
  def extract_tuple_items(prop_def)
    items_schema = prop_def['items']
    return nil unless items_schema.is_a?(Array)

    items_schema.map { |item_schema| convert_schema_to_type(item_schema) }
  end

  # Check if items is a tuple (array of schemas) vs a single schema
  # When items is a single schema, additionalItems has no effect per JSON Schema spec
  def items_is_tuple?(prop_def)
    prop_def['items'].is_a?(Array)
  end

  def extract_constraints(prop_def)
    constraints = CONSTRAINT_KEYS.each_with_object({}) do |(json_key, ruby_key), result|
      result[ruby_key] = prop_def[json_key] if prop_def.key?(json_key)
    end

    # Add tuple items if present (items is an array of schemas)
    tuple_items = extract_tuple_items(prop_def)
    constraints[:items] = tuple_items if tuple_items

    # Per JSON Schema spec: additionalItems only applies when items is an array (tuple)
    # When items is a single schema, additionalItems has no effect
    constraints.delete(:additional_items) unless items_is_tuple?(prop_def)

    # Convert additionalItems schema to Ruby type if it's a schema object
    constraints[:additional_items] = convert_schema_to_type(constraints[:additional_items]) if constraints[:additional_items].is_a?(Hash)

    constraints
  end

  # Convert a JSON Schema type definition to a Ruby type
  def convert_schema_to_type(schema)
    return T.untyped unless schema.is_a?(Hash) && schema.key?('type')

    TYPE_MAPPING.fetch(schema['type'], T.untyped)
  end

  def extract_object_constraints(schema_data)
    return {} unless schema_data.is_a?(Hash)

    OBJECT_CONSTRAINT_KEYS.each_with_object({}) do |(json_key, ruby_key), constraints|
      # Convert decimal values to integers for minProperties/maxProperties
      if schema_data.key?(json_key)
        value = schema_data[json_key]
        constraints[ruby_key] = value.is_a?(Float) ? value.to_i : value
      end
    end
  end
end
