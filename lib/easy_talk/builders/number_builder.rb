require_relative 'base_builder'

module EasyTalk
  module Builders
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

      sig { params(name: Symbol, options: T::Hash[Symbol, T.nilable(T.any(String, Integer))]).void }
      def initialize(name, options = {})
        super(name, { type: 'number' }, options)
      end
    end
  end
end
