require_relative 'base_builder'

module EsquemaBase
  module Builders
    class StringBuilder < BaseBuilder
      def initialize(name, options = {})
        super(name, { type: 'string' }, options)
      end
    end
  end
end
