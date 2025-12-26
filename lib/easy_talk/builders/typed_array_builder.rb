# frozen_string_literal: true

require_relative 'collection_helpers'

module EasyTalk
  module Builders
    # Builder class for array properties.
    class TypedArrayBuilder < BaseBuilder
      extend CollectionHelpers
      extend T::Sig

      VALID_OPTIONS = {
        min_items: { type: Integer, key: :minItems },
        max_items: { type: Integer, key: :maxItems },
        unique_items: { type: T::Boolean, key: :uniqueItems },
        enum: { type: T::Array[T.untyped], key: :enum },
        const: { type: T::Array[T.untyped], key: :const },
        ref: { type: T::Boolean, key: :ref }
      }.freeze

      attr_reader :type

      sig { params(name: Symbol, type: T.untyped, constraints: Hash).void }
      def initialize(name, type, constraints = {})
        @name = name
        @type = type
        update_option_types
        super(name, { type: 'array' }, constraints, VALID_OPTIONS)
      end

      private

      # Modifies the schema to include the `items` property.
      #
      # @return [Hash] The built schema.
      sig { returns(T::Hash[Symbol, T.untyped]) }
      def schema
        super.tap do |schema|
          # Pass ref constraint to items if present (for nested model references)
          item_constraints = @options&.slice(:ref) || {}
          schema[:items] = Property.new(@name, inner_type, item_constraints).build
        end
      end

      def inner_type
        return unless type.is_a?(T::Types::TypedArray)

        if type.type.is_a?(EasyTalk::Types::Composer)
          type.type
        else
          type.type.raw_type
        end
      end

      sig { void }
      # Updates the option types for the array builder.
      def update_option_types
        VALID_OPTIONS[:enum][:type] = T::Array[inner_type]
        VALID_OPTIONS[:const][:type] = T::Array[inner_type]
      end
    end
  end
end
