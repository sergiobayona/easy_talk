# frozen_string_literal: true

require_relative 'base_builder'

module EasyTalk
  module Builders
    class ArrayBuilder < BaseBuilder
      # The `VALID_OPTIONS` constant is a hash that defines the valid options for an array property.
      VALID_OPTIONS = {
        min_items: { type: Integer, key: :minItems },
        max_items: { type: Integer, key: :maxItems },
        unique_items: { type: T::Boolean, key: :uniqueItems },
        enum: { type: T::Array[T.untyped], key: :enum },
        const: { type: T::Array[T.untyped], key: :const }
      }.freeze

      # Initializes a new instance of the ArrayBuilder class.
      sig { params(name: Symbol, type: T.untyped, options: T::Hash[Symbol, T.untyped]).void }
      def initialize(name, type, options = {})
        @inner_type = type.respond_to?(:raw_type) ? type.raw_type : type
        update_option_types
        super(name, { type: 'array' }, options, VALID_OPTIONS)
      end

      # Modifies the schema to include the `items` property.
      #
      # @return [Hash] The built schema.
      sig { returns(T::Hash[Symbol, T.untyped]) }
      def schema
        super.tap do |schema|
          schema[:items] = Property.new(name, @inner_type).build
        end
      end

      private

      sig { void }
      # Updates the option types for the array builder.
      def update_option_types
        VALID_OPTIONS[:enum][:type] = T::Array[@inner_type]
        VALID_OPTIONS[:const][:type] = T::Array[@inner_type]
      end
    end
  end
end
