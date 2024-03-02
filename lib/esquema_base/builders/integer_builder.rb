require_relative 'base_builder'

module EsquemaBase
  module Builders
    class IntegerBuilder < BaseBuilder
      extend T::Sig
      VALID_OPTIONS = {
        title: { type: T.nilable(String), key: :title },
        description: { type: T.nilable(String), key: :description },
        minimum: { type: Integer, key: :minimum },
        maximum: { type: Integer, key: :maximum },
        exclusive_minimum: { type: Integer, key: :exclusiveMinimum },
        exclusive_maximum: { type: Integer, key: :exclusiveMaximum },
        multiple_of: { type: Integer, key: :multipleOf },
        enum: { type: T::Array[Integer], key: :enum },
        const: { type: Integer, key: :const },
        default: { type: Integer, key: :default }
      }

      sig { params(name: String, options: T::Hash[Symbol, T.nilable(T.any(String, Integer))]).void }
      def initialize(name, options = {})
        options.assert_valid_keys(VALID_OPTIONS.keys)
        @name = name
        @options = options
        @valid_options = VALID_OPTIONS
        @schema = { type: 'integer' }
      end
    end
  end
end
