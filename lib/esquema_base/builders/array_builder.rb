require_relative 'base_builder'
require 'pry-byebug'

module EsquemaBase
  module Builders
    class ArrayBuilder < BaseBuilder
      VALID_OPTIONS = {
        title: { type: T.nilable(String), key: :title },
        description: { type: T.nilable(String), key: :description },
        min_items: { type: Integer, key: :minItems },
        max_items: { type: Integer, key: :maxItems },
        unique_items: { type: T::Boolean, key: :uniqueItems },
        enum: { type: T::Array[T.untyped], key: :enum },
        const: { type: T::Array[T.untyped], key: :const }
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
        # overide the type of the enum and const options to be an array of the inner type
        VALID_OPTIONS[:enum][:type] = T::Array[inner_type]
        VALID_OPTIONS[:const][:type] = T::Array[inner_type]

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
