require_relative 'base_builder'

module EsquemaBase
  module Builders
    class NumberBuilder < BaseBuilder
      def initialize(name, options = {})
        super(name, { type: 'number' }, options)
      end
    end
  end
end
