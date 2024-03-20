# frozen_string_literal: true

require_relative 'base_builder'

module EasyTalk
  module Builders
    # Base builder class for array-type properties.
    class UnionBuilder < BaseBuilder
      sig { params(context: T.untyped, name: Symbol).void }
      def initialize(context, name)
        @name = name
        @type = context[name].type
        @context = context.dup
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
