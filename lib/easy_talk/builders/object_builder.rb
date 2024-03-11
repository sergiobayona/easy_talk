# frozen_string_literal: true

module EasyTalk
  module Builders
    # Builder class for json schema objects.
    class ObjectBuilder < BaseBuilder
      extend T::Sig

      attr_reader :klass

      VALID_OPTIONS = {
        properties: { type: T::Hash[Symbol, T.untyped], key: :properties },
        additional_properties: { type: T::Boolean, key: :additionalProperties },
        required: { type: T::Array[Symbol], key: :required },
        defs: { type: T::Hash[Symbol, T.untyped], key: :$defs },
        allOf: { type: T::Array[T.untyped], key: :allOf }
      }.freeze

      sig { params(schema_definition: EasyTalk::SchemaDefinition).void }
      def initialize(schema_definition)
        @schema_definition = schema_definition
        @klass = schema_definition.klass
        name = schema_definition.klass.name ? schema_definition.klass.name.to_sym : :klass
        @required_properties = []
        super(name, { type: 'object' }, options, VALID_OPTIONS)
      end

      private

      def properties_from_schema_definition(schema_definition)
        schema = schema_definition.each_with_object({}) do |(property_name, options), hash|
          type = options.delete(:type)
          @required_properties << property_name unless type.respond_to?(:nilable?) && type.nilable?
          hash[property_name] = Property.new(property_name, type, options)
        end

        EasyTalk.add_schema(klass.name.to_sym, schema)
        schema
      end

      def defs_from_schemas
        return unless klass.inherits_schema?

        EasyTalk.schemas.slice(klass.inherits_from.name.to_sym)
      end

      def all_of
        return unless klass.inherits_schema?

        [
          { '$ref': klass.inherits_from.ref_template }
        ]
      end

      def options
        @options = @schema_definition.to_h
        @options[:properties] = properties_from_schema_definition(properties)
        @options[:defs] = defs_from_schemas
        @options[:allOf] = all_of
        @options[:required] = @required_properties
        @options.reject! { |_key, value| [nil, [], {}].include?(value) }
        @options
      end

      def properties
        @schema_definition.to_h[:properties] || {}
      end
    end
  end
end
