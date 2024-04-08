# frozen_string_literal: true

require_relative 'base_builder'

module EasyTalk
  module Builders
    # builder class for Null properties.
    class NullBuilder < BaseBuilder
      # Initializes a new instance of the NullBuilder class.
      sig { params(name: Symbol, _type: T.untyped, _constraints: Hash).void }
      def initialize(name, _type = nil, _constraints = {})
        super(name, { type: 'null' }, {}, {})
      end
    end
  end
end
