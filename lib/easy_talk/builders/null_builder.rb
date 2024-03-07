# frozen_string_literal: true

require_relative 'base_builder'

module EasyTalk
  module Builders
    # This class represents a builder for Null properties.
    class NullBuilder < BaseBuilder
      VALID_OPTIONS = {}.freeze

      # Initializes a new instance of the NullBuilder class.
      sig { params(name: Symbol, options: T::Hash[Symbol, T.nilable(T.any(String, Integer))]).void }
      def initialize(name, options = {})
        super(name, { type: 'null' }, options, VALID_OPTIONS)
      end
    end
  end
end
