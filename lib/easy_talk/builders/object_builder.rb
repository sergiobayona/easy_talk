# frozen_string_literal: true

module EasyTalk
  module Builders
    # Builder class for json schema objects.
    class ObjectBuilder < BaseBuilder
      extend T::Sig

      VALID_OPTIONS = {
        properties: { type: T::Hash[Symbol, T.untyped], key: :properties },
        additional_properties: { type: T::Boolean, key: :additionalProperties },
        required: { type: T::Array[Symbol], key: :required }
      }.freeze

      sig { params(schema_definition: EasyTalk::SchemaDefinition).void }
      def initialize(schema_definition)
        @schema_definition = schema_definition
        name = schema_definition.klass.name ? schema_definition.klass.name.to_sym : :klass
        @required_properties = []
        super(name, { type: 'object' }, options, VALID_OPTIONS)
      end

      private

      def properties_from_schema_definition(schema_definition)
        schema_definition.to_h.each_with_object({}) do |(property_name, options), hash|
          type = options.delete(:type)
          @required_properties << property_name unless options[:optional]
          hash[property_name] = Property.new(property_name, type, options)
        end
      end

      def options
        @options = @schema_definition.to_h
        @options[:properties] = properties_from_schema_definition(properties)
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
