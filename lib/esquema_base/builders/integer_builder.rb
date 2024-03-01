require_relative 'base_builder'

module EsquemaBase
  module Builders
    class IntegerBuilder < BaseBuilder
      def initialize(name, options = {})
        schema = { type: 'integer' }
        super(name, schema, options)
      end
    end
  end
end
