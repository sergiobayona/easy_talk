require_relative 'base_builder'

module EsquemaBase
  module Builders
    class NullBuilder < BaseBuilder
      def initialize(name, options = {})
        schema = { type: 'null' }
        super(name, schema, options)
      end
    end
  end
end
