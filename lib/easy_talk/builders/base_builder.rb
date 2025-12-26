# frozen_string_literal: true
# typed: true

module EasyTalk
  module Builders
    # BaseBuilder is a class that provides a common structure for building schema properties
    class BaseBuilder
      extend T::Sig

      # BaseBuilder is a class that provides a common structure for building objects
      # representing schema properties.
      COMMON_OPTIONS = {
        title: { type: T.nilable(String), key: :title },
        description: { type: T.nilable(String), key: :description },
        optional: { type: T.nilable(T::Boolean), key: :optional },
        as: { type: T.nilable(T.any(String, Symbol)), key: :as }
      }.freeze

      attr_reader :property_name, :schema, :options

      sig do
        params(
          property_name: Symbol,
          schema: T::Hash[Symbol, T.untyped],
          options: T::Hash[Symbol, String],
          valid_options: T::Hash[Symbol, T.untyped]
        ).void
      end
      # Initializes a new instance of the BaseBuilder class.
      #
      # @param property_name [Symbol] The name of the property.
      # @param schema [Hash] A hash representing a json schema object.
      # @param options [Hash] The options for the builder (default: {}).
      # @param valid_options [Hash] The acceptable options for the given property type (default: {}).
      def initialize(property_name, schema, options = {}, valid_options = {})
        @valid_options = COMMON_OPTIONS.merge(valid_options)
        EasyTalk.assert_valid_property_options(property_name, options, @valid_options.keys)
        @property_name = property_name
        @schema = schema
        @options = options
      end

      # Builds the schema object based on the provided options.
      sig { returns(T::Hash[Symbol, T.untyped]) }
      def build
        @valid_options.except(:ref).each_with_object(schema) do |(constraint_name, value), obj|
          next if @options[constraint_name].nil?

          # Use our centralized validation
          ErrorHelper.validate_constraint_value(
            property_name: property_name,
            constraint_name: constraint_name,
            value_type: value[:type],
            value: @options[constraint_name]
          )

          obj[value[:key]] = @options[constraint_name]
        end
      end

      def self.collection_type?
        false
      end
    end
  end
end
