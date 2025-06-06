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

        # Extract and build sub-schemas first (handles allOf/anyOf/oneOf references, etc.)
        process_subschemas(merged)

        # Build :properties into a final form (and find "required" props)
        merged[:properties] = build_properties(merged.delete(:properties))

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

        properties_hash.each_with_object({}) do |(prop_name, prop_options), result|
          cache_key = [prop_name, prop_options].hash

          # Use cache if the exact property and configuration have been processed before
          @properties_cache[cache_key] ||= begin
            mark_required_unless_optional(prop_name, prop_options)
            build_property(prop_name, prop_options)
          end

          result[prop_name] = @properties_cache[cache_key]
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
      #
      def build_property(prop_name, prop_options)
        @property_cache ||= {}

        # Memoize so we only build each property once
        @property_cache[prop_name] ||= begin
          # Remove optional constraints from the property
          constraints = prop_options[:constraints].except(:optional)
          # Normal property: e.g. { type: String, constraints: {...} }
          Property.new(prop_name, prop_options[:type], constraints)
        end
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
