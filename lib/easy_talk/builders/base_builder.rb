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
        optional: { type: T.nilable(T::Boolean), key: :optional }
      }.freeze

      attr_reader :name, :schema, :options

      sig do
        params(
          name: Symbol,
          schema: T::Hash[Symbol, T.untyped],
          options: T::Hash[Symbol, String],
          valid_options: T::Hash[Symbol, T.untyped]
        ).void
      end
      # Initializes a new instance of the BaseBuilder class.
      #
      # @param name [Symbol] The name of the property.
      # @param schema [Hash] A hash representing a json schema object.
      # @param options [Hash] The options for the builder (default: {}).
      # @param valid_options [Hash] The acceptable options for the given property type (default: {}).
      def initialize(name, schema, options = {}, valid_options = {})
        @valid_options = COMMON_OPTIONS.merge(valid_options)
        options.assert_valid_keys(@valid_options.keys)
        @name = name
        @schema = schema
        @options = options
      end

      # Builds the schema object based on the provided options.
      sig { returns(T::Hash[Symbol, T.untyped]) }
      def build
        @valid_options.each_with_object(schema) do |(key, value), obj|
          next if @options[key].nil?

          # Work around for Sorbet's default inability to type check the items inside an array

          if value[:type].respond_to?(:recursively_valid?) && !value[:type].recursively_valid?(@options[key])
            raise TypeError, "Invalid type for #{key}"
          end

          obj[value[:key]] = T.let(@options[key], value[:type])
        end
      end

      def self.collection_type?
        false
      end
    end
  end
end
