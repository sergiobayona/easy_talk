require_relative 'base_builder'

module EsquemaBase
  module Builders
    class BooleanBuilder < BaseBuilder
      def initialize(name, options = {})
        super(name, { type: 'boolean' }, options)
      end
    end
  end
end
