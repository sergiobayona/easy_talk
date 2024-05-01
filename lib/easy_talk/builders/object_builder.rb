# frozen_string_literal: true

require_relative 'base_builder'

module EasyTalk
  module Builders
    # Builder class for json schema objects.
    class ObjectBuilder < BaseBuilder
      extend T::Sig

      attr_reader :schema

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
        @schema_definition = schema_definition
        @schema = schema_definition.schema.dup
        @required_properties = []
        name = schema_definition.name ? schema_definition.name.to_sym : :klass
        super(name, { type: 'object' }, options, VALID_OPTIONS)
      end

      private

      def properties_from_schema_definition
        properties = schema.delete(:properties) || {}
        properties.each_with_object({}) do |(property_name, options), context|
          add_required_property(property_name, options)
          context[property_name] = build_property(property_name, options)
        end
      end

      # rubocop:disable Style/DoubleNegation
      def add_required_property(property_name, options)
        return if options.is_a?(Hash) && !!(options[:type].respond_to?(:nilable?) && options[:type].nilable?)

        return if options.respond_to?(:optional?) && options.optional?

        @required_properties << property_name
      end
      # rubocop:enable Style/DoubleNegation

      def build_property(property_name, options)
        if options.is_a?(EasyTalk::SchemaDefinition)
          ObjectBuilder.new(options).build
        else
          Property.new(property_name, options[:type], options[:constraints])
        end
      end

      def subschemas_from_schema_definition
        subschemas = schema.delete(:subschemas) || []
        subschemas.each do |subschema|
          add_definitions(subschema)
          add_references(subschema)
        end
      end

      def add_definitions(subschema)
        definitions = subschema.items.each_with_object({}) do |item, hash|
          hash[item.name] = item.schema
        end
        schema[:defs] = definitions
      end

      def add_references(subschema)
        references = subschema.items.map do |item|
          { '$ref': item.ref_template }
        end
        schema[subschema.name] = references
      end

      def options
        @options = schema
        subschemas_from_schema_definition
        @options[:properties] = properties_from_schema_definition
        @options[:required] = @required_properties
        @options.reject! { |_key, value| [nil, [], {}].include?(value) }
        @options
      end
    end
  end
end
