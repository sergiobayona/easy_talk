require_relative 'base_builder'

module EasyTalk
  module Builders
    class BooleanBuilder < BaseBuilder
      extend T::Sig

      VALID_OPTIONS = {
        enum: { type: T::Array[T::Boolean], key: :enum },
        const: { type: T::Boolean, key: :const },
        default: { type: T::Boolean, key: :default }
      }.freeze

      sig { params(name: Symbol, options: T::Hash[Symbol, T.nilable(T.any(String, Integer))]).void }
      def initialize(name, options = {})
        super(name, { type: 'boolean' }, options, VALID_OPTIONS)
      end
    end
  end
end
