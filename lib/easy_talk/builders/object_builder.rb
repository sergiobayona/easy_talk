# frozen_string_literal: true

require_relative 'base_builder'

module EasyTalk
  module Builders
    #
    # ObjectBuilder is responsible for turning a SchemaDefinition of an "object" type
    # into a validated JSON Schema hash. It:
    #
    # 1) Recursively processes the schema's :properties,
    # 2) Determines which properties are required (unless optional),
    # 3) Handles sub-schema composition (allOf, anyOf, oneOf, not),
    # 4) Produces the final object-level schema hash.
    #
    class ObjectBuilder < BaseBuilder
      extend T::Sig

      # Required by BaseBuilder: recognized schema options for "object" types
      VALID_OPTIONS = {
        properties: { type: T::Hash[T.any(Symbol, String), T.untyped], key: :properties },
        additional_properties: { type: T::Boolean, key: :additionalProperties },
        subschemas: { type: T::Array[T.untyped], key: :subschemas },
        required: { type: T::Array[T.any(Symbol, String)], key: :required },
        defs: { type: T.untyped, key: :$defs },
        allOf: { type: T.untyped, key: :allOf },
        anyOf: { type: T.untyped, key: :anyOf },
        oneOf: { type: T.untyped, key: :oneOf },
        not: { type: T.untyped, key: :not }
      }.freeze

      sig { params(schema_definition: EasyTalk::SchemaDefinition).void }
      def initialize(schema_definition)
        # Keep a reference to the original schema definition
        @schema_definition = schema_definition
        # Duplicate the raw schema hash so we can mutate it safely
        @original_schema = schema_definition.schema.dup

        # We'll collect required property names in this Set
        @required_properties = Set.new

        # Collect models that are referenced via $ref for $defs generation
        @ref_models = Set.new

        # Usually the name is a string (class name). Fallback to :klass if nil.
        name_for_builder = schema_definition.name ? schema_definition.name.to_sym : :klass

        # Build the base structure: { type: 'object' } plus any top-level options
        super(
          name_for_builder,
          { type: 'object' },    # minimal "object" structure
          build_options_hash,    # method below merges & cleans final top-level keys
          VALID_OPTIONS
        )
      end

      private

      ##
      # Main aggregator: merges the top-level schema keys (like :properties, :subschemas)
      # into a single hash that we'll feed to BaseBuilder.
      def build_options_hash
        # Start with a copy of the raw schema
        merged = @original_schema.dup

        # Remove schema_version and schema_id as they're handled separately in json_schema output
        merged.delete(:schema_version)
        merged.delete(:schema_id)

        # Extract and build sub-schemas first (handles allOf/anyOf/oneOf references, etc.)
        process_subschemas(merged)

        # Build :properties into a final form (and find "required" props)
        # This also collects models that use $ref into @ref_models
        merged[:properties] = build_properties(merged.delete(:properties))

        # Add $defs for any models that are referenced via $ref
        add_ref_model_defs(merged) if @ref_models.any?

        # Populate the final "required" array from @required_properties
        merged[:required] = @required_properties.to_a if @required_properties.any?

        # Add additionalProperties: false by default if not explicitly set
        merged[:additional_properties] = false unless merged.key?(:additional_properties)

        # Prune empty or nil values so we don't produce stuff like "properties": {} unnecessarily
        merged.reject! { |_k, v| v.nil? || v == {} || v == [] }

        merged
      end

      ##
      # Given the property definitions hash, produce a new hash of
      # { property_name => [Property or nested schema builder result] }.
      #
      def build_properties(properties_hash)
        return {} unless properties_hash.is_a?(Hash)

        # Cache with a key based on property name and its full configuration
        @properties_cache ||= {}

        properties_hash.each_with_object({}) do |(_prop_name, prop_options), result|
          property_name = prop_options[:constraints].delete(:as).to_sym
          cache_key = [property_name, prop_options].hash

          # Use cache if the exact property and configuration have been processed before
          @properties_cache[cache_key] ||= begin
            mark_required_unless_optional(property_name, prop_options)
            build_property(property_name, prop_options)
          end

          result[property_name] = @properties_cache[cache_key]
        end
      end

      ##
      # Decide if a property should be required. If it's optional or nilable,
      # we won't include it in the "required" array.
      #
      def mark_required_unless_optional(prop_name, prop_options)
        return if property_optional?(prop_options)

        @required_properties.add(prop_name)
      end

      ##
      # Returns true if the property is declared optional.
      #
      def property_optional?(prop_options)
        # Check constraints[:optional]
        return true if prop_options.dig(:constraints, :optional)

        # Check for nil_optional config to determine if nilable should also mean optional
        return EasyTalk.configuration.nilable_is_optional if prop_options[:type].respond_to?(:nilable?) && prop_options[:type].nilable?

        false
      end

      ##
      # Builds a single property. Could be a nested schema if it has sub-properties,
      # or a standard scalar property (String, Integer, etc.).
      # Also tracks EasyTalk models that should be added to $defs when using $ref.
      #
      def build_property(prop_name, prop_options)
        @property_cache ||= {}

        # Memoize so we only build each property once
        @property_cache[prop_name] ||= begin
          # Remove optional constraints from the property
          constraints = prop_options[:constraints].except(:optional)
          prop_type = prop_options[:type]

          # Track models that will use $ref for later $defs generation
          collect_ref_models(prop_type, constraints)

          # Normal property: e.g. { type: String, constraints: {...} }
          Property.new(prop_name, prop_type, constraints)
        end
      end

      ##
      # Collects EasyTalk models that will be referenced via $ref.
      # These models need to be added to $defs in the final schema.
      #
      def collect_ref_models(prop_type, constraints)
        # Check if this type should use $ref
        if should_collect_ref?(prop_type, constraints)
          @ref_models.add(prop_type)
        # Handle typed arrays with EasyTalk model items
        elsif typed_array_with_model?(prop_type)
          inner_type = prop_type.type.raw_type
          @ref_models.add(inner_type) if should_collect_ref?(inner_type, constraints)
        # Handle nilable types
        elsif nilable_with_model?(prop_type)
          actual_type = T::Utils::Nilable.get_underlying_type(prop_type)
          @ref_models.add(actual_type) if should_collect_ref?(actual_type, constraints)
        end
      end

      ##
      # Determines if a type should be collected for $ref based on config and constraints.
      #
      def should_collect_ref?(check_type, constraints)
        return false unless easytalk_model?(check_type)

        # Per-property constraint takes precedence
        return constraints[:ref] if constraints.key?(:ref)

        # Fall back to global configuration
        EasyTalk.configuration.use_refs
      end

      ##
      # Checks if a type is an EasyTalk model.
      #
      def easytalk_model?(check_type)
        check_type.is_a?(Class) &&
          check_type.respond_to?(:schema) &&
          check_type.respond_to?(:ref_template) &&
          defined?(EasyTalk::Model) &&
          check_type.include?(EasyTalk::Model)
      end

      ##
      # Checks if type is a typed array containing an EasyTalk model.
      #
      def typed_array_with_model?(prop_type)
        return false unless prop_type.is_a?(T::Types::TypedArray)

        inner_type = prop_type.type.raw_type
        easytalk_model?(inner_type)
      end

      ##
      # Checks if type is nilable and contains an EasyTalk model.
      #
      def nilable_with_model?(prop_type)
        return false unless prop_type.respond_to?(:types)
        return false unless prop_type.types.all? { |t| t.respond_to?(:raw_type) }
        return false unless prop_type.types.any? { |t| t.raw_type == NilClass }

        actual_type = T::Utils::Nilable.get_underlying_type(prop_type)
        easytalk_model?(actual_type)
      end

      ##
      # Adds $defs entries for all collected ref models.
      #
      def add_ref_model_defs(schema_hash)
        definitions = @ref_models.each_with_object({}) do |model, acc|
          acc[model.name] = model.schema
        end

        existing_defs = schema_hash[:defs] || {}
        schema_hash[:defs] = existing_defs.merge(definitions)
      end

      ##
      # Process top-level composition keywords (e.g. allOf, anyOf, oneOf),
      # converting them to definitions + references if appropriate.
      #
      def process_subschemas(schema_hash)
        subschemas = schema_hash.delete(:subschemas) || []
        subschemas.each do |subschema|
          add_defs_from_subschema(schema_hash, subschema)
          add_refs_from_subschema(schema_hash, subschema)
        end
      end

      ##
      # For each item in the composer, add it to :defs so that we can reference it later.
      #
      def add_defs_from_subschema(schema_hash, subschema)
        # Build up a hash of class_name => schema for each sub-item
        definitions = subschema.items.each_with_object({}) do |item, acc|
          acc[item.name] = item.schema
        end
        # Merge or create :defs
        existing_defs = schema_hash[:defs] || {}
        schema_hash[:defs] = existing_defs.merge(definitions)
      end

      ##
      # Add references to the schema for each sub-item in the composer
      # e.g. { "$ref": "#/$defs/SomeClass" }
      #
      def add_refs_from_subschema(schema_hash, subschema)
        references = subschema.items.map { |item| { '$ref': item.ref_template } }
        schema_hash[subschema.name] = references
      end
    end
  end
end
