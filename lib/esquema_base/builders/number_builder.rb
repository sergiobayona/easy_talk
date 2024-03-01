require_relative 'base_builder'

module EsquemaBase
  module Builders
    class NumberBuilder < BaseBuilder
      def initialize(name, options = {})
        schema = { type: 'number' }
        super(name, schema, options)
      end
    end
  end
end
