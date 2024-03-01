require_relative 'base_builder'

module EsquemaBase
  module Builders
    class ObjectBuilder < BaseBuilder
      def initialize(name, options = {})
        super(name, { type: 'object' }, options)
      end
    end
  end
end
