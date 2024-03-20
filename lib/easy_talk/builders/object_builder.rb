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
        all_of: { type: T::Array[T.untyped], key: :allOf },
        any_of: { type: T::Array[T.untyped], key: :anyOf },
        one_of: { type: T::Array[T.untyped], key: :oneOf },
        not: { type: T.untyped, key: :not }
      }.freeze

      sig { params(schema_definition: EasyTalk::SchemaDefinition).void }
      def initialize(schema_definition)
        @schema_definition = schema_definition
        name = schema_definition.name ? schema_definition.name.to_sym : :klass
        @required_properties = []
        super(name, { type: 'object' }, options, VALID_OPTIONS)
      end

      private

      def properties_from_schema_definition(properties)
        properties.each_with_object({}) do |(property_name, options), context|
          @required_properties << property_name unless options[:type].respond_to?(:nilable?) && options[:type].nilable?
          context[property_name] = Property.new(context, property_name, options[:type], options[:constraints])
        end
      end

      def options
        @options = @schema_definition.schema.dup
        @options[:properties] = properties_from_schema_definition(properties)
        @options[:required] = @required_properties
        @options.reject! { |_key, value| [nil, [], {}].include?(value) }
        @options
      end

      def properties
        @schema_definition.schema[:properties] || {}
      end
    end
  end
end
