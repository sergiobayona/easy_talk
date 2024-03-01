require_relative 'base_builder'

module EsquemaBase
  module Builders
    class NullBuilder < BaseBuilder
      def initialize(name, options = {})
        super(name, { type: 'null' }, options)
      end
    end
  end
end
