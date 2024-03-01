require_relative 'base_builder'

module EsquemaBase
  module Builders
    class BooleanBuilder < BaseBuilder
      def initialize(name, options = {})
        schema = { type: 'boolean' }
        super(name, schema, options)
      end
    end
  end
end
