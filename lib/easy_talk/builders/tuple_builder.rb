# frozen_string_literal: true
# typed: true

module EasyTalk
  module Builders
    # Builder class for tuple array properties (T::Tuple[Type1, Type2, ...]).
    #
    # Tuples are arrays with positional type validation where each index
    # has a specific expected type.
    #
    # @example Basic tuple
    #   property :coordinates, T::Tuple[Float, Float]
    #
    # @example Tuple with additional items constraint
    #   property :record, T::Tuple[String, Integer], additional_items: false
    #
    class TupleBuilder < BaseBuilder
      extend T::Sig

      # NOTE: additional_items is handled separately in build() since it can be a type
      VALID_OPTIONS = {
        min_items: { type: Integer, key: :minItems },
        max_items: { type: Integer, key: :maxItems },
        unique_items: { type: T::Boolean, key: :uniqueItems }
      }.freeze

      attr_reader :type

      sig { params(name: Symbol, type: Types::Tuple, constraints: T::Hash[Symbol, T.untyped]).void }
      def initialize(name, type, constraints = {})
        @name = name
        @type = type
        # Work on a copy to avoid mutating the original constraints hash
        local_constraints = constraints.dup
        # Extract additional_items before passing to super (it's handled separately in build)
        @additional_items_constraint = local_constraints.delete(:additional_items)
        super(name, { type: 'array' }, local_constraints, VALID_OPTIONS)
      end

      sig { returns(T::Boolean) }
      def self.collection_type?
        true
      end

      # Builds the tuple schema with positional items.
      #
      # @return [Hash] The built schema.
      sig { returns(T::Hash[Symbol, T.untyped]) }
      def build
        schema = super

        # Build items array from tuple types
        schema[:items] = build_items

        # Handle additional_items constraint
        schema[:additionalItems] = build_additional_items_schema(@additional_items_constraint) unless @additional_items_constraint.nil?

        schema
      end

      private

      # Builds the items array from tuple types.
      #
      # @return [Array<Hash>] Array of schemas for each position
      sig { returns(T::Array[T::Hash[Symbol, T.untyped]]) }
      def build_items
        type.types.map.with_index do |item_type, index|
          Property.new(:"#{@name}_item_#{index}", item_type, {}).build
        end
      end

      # Builds the additionalItems schema value.
      #
      # @param value [Boolean, Class] The additional_items constraint
      # @return [Boolean, Hash] The schema value for additionalItems
      sig { params(value: T.untyped).returns(T.any(T::Boolean, T::Hash[Symbol, T.untyped])) }
      def build_additional_items_schema(value)
        case value
        when true, false
          value
        else
          # It's a type - build a schema for it
          Property.new(:"#{@name}_additional", value, {}).build
        end
      end
    end
  end
end
