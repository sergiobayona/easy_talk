require_relative 'base_builder'

module EsquemaBase
  module Builders
    class BooleanBuilder < BaseBuilder
      extend T::Sig

      VALID_OPTIONS = {
        title: { type: T.nilable(String), key: :title },
        description: { type: T.nilable(String), key: :description },
        enum: { type: T::Array[T::Boolean], key: :enum },
        const: { type: T::Boolean, key: :const },
        default: { type: T::Boolean, key: :default }
      }

      def initialize(name, options = {})
        options.assert_valid_keys(VALID_OPTIONS.keys)
        @name = name
        @options = options
        @schema = { type: 'boolean' }
      end
    end
  end
end
