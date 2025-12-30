# frozen_string_literal: true
# typed: true

require_relative 'base_builder'

module EasyTalk
  module Builders
    # builder class for Null properties.
    class NullBuilder < BaseBuilder
      extend T::Sig

      # Initializes a new instance of the NullBuilder class.
      sig { params(name: Symbol, _constraints: T::Hash[Symbol, T.untyped]).void }
      def initialize(name, _constraints = {})
        super(name, { type: 'null' }, {}, {})
      end
    end
  end
end
