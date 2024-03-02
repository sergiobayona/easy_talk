require_relative 'base_builder'

module EsquemaBase
  module Builders
    class ArrayBuilder < BaseBuilder
      VALID_OPTIONS = {
        title: { type: T.nilable(String), key: :title },
        description: { type: T.nilable(String), key: :description },
        min_items: { type: T.nilable(Integer), key: :minItems },
        max_items: { type: T.nilable(Integer), key: :maxItems },
        unique_items: { type: T.nilable(T::Boolean), key: :uniqueItems },
        enum: { type: T.nilable(T::Array[T.untyped]), key: :enum },
        const: { type: T.nilable(T::Array[T.untyped]), key: :const }
      }

      def initialize(name, inner_type, options = {})
        options.assert_valid_keys(VALID_OPTIONS.keys)
        @name = name
        @inner_type = inner_type
        @options = options
        @schema = { type: 'array' }
      end

      def self.build(name, inner_type, options)
        builder = new(name, inner_type, options)
        builder.build_property
      end

      def build_property
        VALID_OPTIONS.each_with_object(schema) do |(key, value), obj|
          next if options[key].nil?

          obj[value[:key]] = T.let(options[key], value[:type])
        end
      end

      def schema
        super.tap do |schema|
          schema[:items] = Property.new(name, inner_type).build_property
        end
      end

      attr_reader :inner_type
    end
  end
end
