# frozen_string_literal: true

require_relative 'base_builder'

module EasyTalk
  module Builders
    # Base builder class for array-type properties.
    class BaseArrayBuilder < BaseBuilder
      # The `VALID_OPTIONS` constant is a hash that defines the valid options for an array property.
      VALID_OPTIONS = {
        min_items: { type: Integer, key: :minItems },
        max_items: { type: Integer, key: :maxItems },
        unique_items: { type: T::Boolean, key: :uniqueItems },
        enum: { type: T::Array[T.untyped], key: :enum },
        const: { type: T::Array[T.untyped], key: :const }
      }.freeze

      sig { params(context: T.untyped, name: Symbol).void }
      def initialize(context, name)
        @context = context
        super(name, { type: 'array' }, constraints, VALID_OPTIONS)
      end

      def constraints; end
    end
  end
end
