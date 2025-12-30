# frozen_string_literal: true
# typed: true

require_relative 'base_builder'

module EasyTalk
  module Builders
    # Builder class for integer properties.
    class IntegerBuilder < BaseBuilder
      extend T::Sig

      VALID_OPTIONS = {
        minimum: { type: Integer, key: :minimum },
        maximum: { type: Integer, key: :maximum },
        exclusive_minimum: { type: Integer, key: :exclusiveMinimum },
        exclusive_maximum: { type: Integer, key: :exclusiveMaximum },
        multiple_of: { type: Integer, key: :multipleOf },
        enum: { type: T::Array[Integer], key: :enum },
        const: { type: Integer, key: :const },
        default: { type: Integer, key: :default }
      }.freeze

      # Initializes a new instance of the IntegerBuilder class.
      sig { params(name: Symbol, constraints: T::Hash[Symbol, T.untyped]).void }
      def initialize(name, constraints = {})
        super(name, { type: 'integer' }, constraints, VALID_OPTIONS)
      end
    end
  end
end
