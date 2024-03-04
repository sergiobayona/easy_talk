require_relative 'base_builder'

module EsquemaBase
  module Builders
    class BooleanBuilder < BaseBuilder
      extend T::Sig

      VALID_OPTIONS = COMMON_OPTIONS.merge({
                                             enum: { type: T::Array[T::Boolean], key: :enum },
                                             const: { type: T::Boolean, key: :const },
                                             default: { type: T::Boolean, key: :default }
                                           }).freeze

      def initialize(name, options = {})
        options.assert_valid_keys(VALID_OPTIONS.keys)
        @name = name
        @options = options
        @valid_options = VALID_OPTIONS
        @schema = { type: 'boolean' }
      end
    end
  end
end
