# frozen_string_literal: true

require_relative 'base_builder'

module EasyTalk
  module Builders
    # Base builder class for array-type properties.
    class UnionBuilder < BaseBuilder
      sig { params(name: Symbol, type: T.untyped).void }
      def initialize(name, type)
        @name = name
        @type = type
        @context = {}
      end

      def build
        @context[@name] = {
          'anyOf' => schemas
        }
      end

      def schemas
        types.map do |type|
          Property.new(@context, @name, type).build
        end
      end

      def types
        @type.types
      end
    end
  end
end
