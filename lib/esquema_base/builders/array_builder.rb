require_relative 'base_builder'

module EsquemaBase
  module Builders
    class ArrayBuilder < BaseBuilder
      def initialize(name, inner_type, options = {})
        @inner_type = inner_type
        super(name, { type: 'array' }, options)
      end

      def self.build(name, inner_type, options)
        builder = new(name, inner_type, options)
        builder.build_property
      end

      def schema
        super.tap do |schema|
          schema[:items] = Property.new(name, inner_type).build_property
        end
      end

      attr_reader :inner_type
    end
  end
end
