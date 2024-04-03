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

      sig do
        params(context: T.untyped, name: Symbol).void
      end
      def initialize(context, name)
        @composer_type = self.class.name.split('::').last
        @name = name
        @type = context[name].type
        @context = context.dup
      end

      def build
        binding.pry
        @context[@name] = {
          'type' => 'object',
          composer_keyword => schemas
        }
      end

      def composer_keyword
        COMPOSER_TO_KEYWORD[@composer_type]
      end

      def schemas
        types.map { |type| type.schema }
      end

      def types
        @type.types
      end
    end
  end
end
