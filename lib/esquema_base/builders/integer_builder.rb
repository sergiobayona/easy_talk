require_relative 'base_builder'

module EsquemaBase
  module Builders
    class IntegerBuilder < BaseBuilder
      extend T::Sig
      VALID_OPTIONS = {
        title: { type: T.nilable(String), key: :title },
        description: { type: T.nilable(String), key: :description },
        minimum: { type: T.nilable(Integer), key: :minimum },
        maximum: { type: T.nilable(Integer), key: :maximum },
        exclusive_minimum: { type: T.nilable(Integer), key: :exclusiveMinimum },
        exclusive_maximum: { type: T.nilable(Integer), key: :exclusiveMaximum },
        multiple_of: { type: T.nilable(Integer), key: :multipleOf },
        enum: { type: T.nilable(T::Array[Integer]), key: :enum },
        const: { type: T.nilable(Integer), key: :const }
      }

      sig { params(name: String, options: T::Hash[Symbol, T.nilable(T.any(String, Integer))]).void }
      def initialize(name, options = {})
        options.assert_valid_keys(VALID_OPTIONS.keys)
        @name = name
        @options = options
        @schema = { type: 'integer' }
      end

      def build_property
        VALID_OPTIONS.each_with_object(schema) do |(key, value), obj|
          next if options[key].nil?

          obj[value[:key]] = T.let(options[key], value[:type])
        end
      end
    end
  end
end
