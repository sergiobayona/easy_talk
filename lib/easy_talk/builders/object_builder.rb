require_relative 'base_builder'
require 'set'

module EasyTalk
  module Builders
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
        @required_properties = Set.new
        name = schema_definition.name ? schema_definition.name.to_sym : :klass
        super(name, { type: 'object' }, options, VALID_OPTIONS)
      end

      private

      def build_properties
        @build_properties ||= begin
          properties = schema.delete(:properties) || {}
          properties.each_with_object({}) do |(property_name, options), context|
            add_required_property(property_name, options)
            context[property_name] = build_property(property_name, options)
          end
        end
      end

      def add_required_property(property_name, options)
        return if property_optional?(options)

        @required_properties.add(property_name)
      end

      def property_optional?(options)
        type_obj = options[:type]
        return true if type_obj.respond_to?(:nilable?) && type_obj.nilable?

        return true if options.dig(:constraints, :optional)

        false
      end

      def build_property(property_name, options)
        @property_cache ||= {}

        @property_cache[property_name] ||= if options[:properties]
                                             ObjectBuilder.new(options[:properties]).build
                                           else
                                             handle_option_type(options)
                                             Property.new(property_name, options[:type], options[:constraints])
                                           end
      end

      def handle_option_type(options)
        if options[:type].respond_to?(:nilable?) && options[:type].nilable? && options[:type].unwrap_nilable.class != T::Types::TypedArray
          options[:type] = options[:type].unwrap_nilable.raw_type
        end
      end

      def subschemas_from_schema_definition
        @subschemas_from_schema_definition ||= begin
          subschemas = schema.delete(:subschemas) || []
          subschemas.each do |subschema|
            add_definitions(subschema)
            add_references(subschema)
          end
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
        @options[:properties] = build_properties
        @options[:required] = @required_properties.to_a
        @options.reject! { |_key, value| [nil, [], {}].include?(value) }
        @options
      end
    end
  end
end
