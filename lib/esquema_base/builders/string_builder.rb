require_relative 'base_builder'

module EsquemaBase
  module Builders
    class StringBuilder < BaseBuilder
      def initialize(name, options = {})
        schema = { type: 'string' }
        super(name, schema, options)
      end
    end
  end
end
