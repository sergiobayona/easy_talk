# frozen_string_literal: true

require_relative 'base_builder'

module EasyTalk
  module Builders
    # builder class for Null properties.
    class NullBuilder < BaseBuilder
      # Initializes a new instance of the NullBuilder class.
      sig { params(context: T.untyped, name: Symbol).void }
      def initialize(context, name)
        @context = context
        super(name, { type: 'null' }, {}, {})
      end
    end
  end
end
