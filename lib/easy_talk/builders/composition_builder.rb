# frozen_string_literal: true

require_relative 'base_builder'

module EasyTalk
  module Builders
    class CompositionBuilder
      extend T::Sig

      COMPOSER_TO_KEYWORD = {
        'AllOfBuilder' => 'allOf',
        'AnyOfBuilder' => 'anyOf',
        'OneOfBuilder' => 'oneOf'
      }.freeze

      sig { params(name: Symbol, type: T.untyped, _constraints: Hash).void }
      def initialize(name, type, _constraints)
        @composer_type = self.class.name.split('::').last
        @name = name
        @type = type
        @context = {}
      end

      def build
        @context[@name.to_sym] = {
          'type' => 'object',
          composer_keyword => schemas
        }
      end

      def composer_keyword
        COMPOSER_TO_KEYWORD[@composer_type]
      end

      def schemas
        items.map { |type| type.schema }
      end

      def items
        @type.items
      end
    end
  end
end
