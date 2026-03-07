# frozen_string_literal: true
# typed: true

require_relative 'collection_helpers'

module EasyTalk
  module Builders
    # Base builder class for array-type properties.
    class UnionBuilder
      extend CollectionHelpers
      extend T::Sig

      VALID_OPTIONS = %i[title description optional as validate].freeze

      sig { params(name: Symbol, type: T.untyped, constraints: T::Hash[Symbol, T.untyped]).void }
      def initialize(name, type, constraints)
        EasyTalk.assert_valid_property_options(name, constraints, VALID_OPTIONS)
        @name = name
        @type = type
        @constraints = constraints
        @context = {}
      end

      sig { returns(T::Hash[Symbol, T.untyped]) }
      def build
        @context[@name] = {
          'anyOf' => schemas
        }
      end

      sig { returns(T::Array[T.untyped]) }
      def schemas
        types.map do |type|
          Property.new(@name, type, @constraints).build
        end
      end

      sig { returns(T.untyped) }
      def types
        @type.types
      end
    end
  end
end
