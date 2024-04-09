# frozen_string_literal: true

require_relative 'base_builder'

module EasyTalk
  module Builders
    # Builder class for boolean properties.
    class BooleanBuilder < BaseBuilder
      extend T::Sig

      # VALID_OPTIONS defines the valid options for a boolean property.
      VALID_OPTIONS = {
        enum: { type: T::Array[T::Boolean], key: :enum },
        const: { type: T::Boolean, key: :const },
        default: { type: T::Boolean, key: :default }
      }.freeze

      sig { params(name: Symbol, _type: T.untyped, constraints: Hash).void }
      def initialize(name, _type = nil, constraints = {})
        super(name, { type: 'boolean' }, constraints, VALID_OPTIONS)
      end
    end
  end
end
