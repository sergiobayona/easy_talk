require_relative 'base_builder'

module EsquemaBase
  module Builders
    class IntegerBuilder < BaseBuilder
      def initialize(name, options = {})
        super(name, { type: 'integer' }, options)
      end
    end
  end
end
