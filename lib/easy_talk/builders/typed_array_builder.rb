# frozen_string_literal: true

require_relative 'base_array_builder'

module EasyTalk
  module Builders
    # Builder class for array properties.
    class TypedArrayBuilder < BaseArrayBuilder
      sig { params(context: T.untyped, name: Symbol).void }
      def initialize(context, name)
        @name = name
        @context = context
        super(context, name)
      end

      private

      def type
        @context[@name].type
      end

      def constraints
        @context[@name].constraints
      end

      attr_reader :context

      # Modifies the schema to include the `items` property.
      #
      # @return [Hash] The built schema.
      sig { returns(T::Hash[Symbol, T.untyped]) }
      def schema
        super.tap do |schema|
          schema[:items] = Property.new(context, @name, inner_type, constraints).build
        end
      end

      def inner_type
        if type.is_a?(T::Types::TypedArray)
          type.type.raw_type
        elsif type.is_a?(T::Types::Union)
          type.types.each do |t|
            return t.type.raw_type
          end
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
