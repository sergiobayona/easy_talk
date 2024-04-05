# frozen_string_literal: true

require_relative 'base_builder'

module EasyTalk
  module Builders
    # Builder class for number properties.
    class NumberBuilder < BaseBuilder
      VALID_OPTIONS = {
        multiple_of: { type: T.any(Integer, Float), key: :multipleOf },
        minimum: { type: T.any(Integer, Float), key: :minimum },
        maximum: { type: T.any(Integer, Float), key: :maximum },
        exclusive_minimum: { type: T.any(Integer, Float), key: :exclusiveMinimum },
        exclusive_maximum: { type: T.any(Integer, Float), key: :exclusiveMaximum },
        enum: { type: T::Array[T.any(Integer, Float)], key: :enum },
        const: { type: T.any(Integer, Float), key: :const },
        default: { type: T.any(Integer, Float), key: :default }
      }.freeze

      # Initializes a new instance of the NumberBuilder class.
      sig { params(name: Symbol, _type: T.untyped, constraints: Hash).void }
      def initialize(name, _type, constraints)
        super(name, { type: 'number' }, constraints, VALID_OPTIONS)
      end
    end
  end
end
