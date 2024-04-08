# frozen_string_literal: true

require_relative 'base_builder'

module EasyTalk
  module Builders
    # Base builder class for array-type properties.
    class UnionBuilder
      extend T::Sig
      sig { params(name: Symbol, type: T.untyped, constraints: T.untyped).void }
      def initialize(name, type, constraints)
        @name = name
        @type = type
        @constraints = constraints
        @context = {}
      end

      def build
        @context[@name] = {
          'anyOf' => schemas
        }
      end

      def schemas
        types.map do |type|
          Property.new(@name, type, @constraints).build
        end
      end

      def types
        @type.types
      end
    end
  end
end
