# frozen_string_literal: true
# typed: true

require_relative 'base_builder'

module EasyTalk
  module Builders
    # builder class for Null properties.
    class NullBuilder < BaseBuilder
      extend T::Sig

      VALID_OPTIONS = {}.freeze

      # Initializes a new instance of the NullBuilder class.
      sig { params(name: Symbol, constraints: T::Hash[Symbol, T.untyped]).void }
      def initialize(name, constraints = {})
        super(name, { type: 'null' }, constraints, VALID_OPTIONS)
      end
    end
  end
end
