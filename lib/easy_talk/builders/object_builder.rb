# frozen_string_literal: true

require_relative 'base_builder'

module EasyTalk
  module Builders
    # Builder class for json schema objects.
    class ObjectBuilder < BaseBuilder
      extend T::Sig

      attr_reader :klass, :schema

      VALID_OPTIONS = {
        properties: { type: T::Hash[Symbol, T.untyped], key: :properties },
        additional_properties: { type: T::Boolean, key: :additionalProperties },
        subschemas: { type: T::Array[T.untyped], key: :subschemas },
        required: { type: T::Array[Symbol], key: :required },
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

      def properties_from_schema_definition(properties)
        properties.each_with_object({}) do |(property_name, options), context|
          @required_properties << property_name unless options[:type].respond_to?(:nilable?) && options[:type].nilable?
          context[property_name] = Property.new(property_name, options[:type], options[:constraints])
        end
      end

      def subschemas_from_schema_definition(subschemas)
        subschemas.each do |subschema|
          definitions = subschema.items.each_with_object({}) do |item, hash|
            hash[item.name] = item.schema
          end
          schema[:defs] = definitions
          references = subschema.items.map do |item|
            { '$ref': item.ref_template }
          end
          schema[subschema.name] = references
        end
      end

      def options
        subschemas_from_schema_definition(subschemas)
        @options = schema
        @options[:properties] = properties_from_schema_definition(properties)
        @options[:required] = @required_properties
        @options.reject! { |_key, value| [nil, [], {}].include?(value) }
        @options
      end

      def properties
        schema.delete(:properties) || {}
      end

      def subschemas
        schema.delete(:subschemas) || []
      end
    end
  end
end
