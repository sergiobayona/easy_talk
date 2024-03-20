# frozen_string_literal: true

require_relative 'base_builder'

module EasyTalk
  module Builders
    # builder class for Null properties.
    class NullBuilder < BaseBuilder
      VALID_OPTIONS = {}.freeze

      # Initializes a new instance of the NullBuilder class.
      sig { params(context: T.untyped, name: Symbol).void }
      def initialize(context, name)
        options = {}
        @context = context
        super(name, { type: 'null' }, options, VALID_OPTIONS)
      end
    end
  end
end
