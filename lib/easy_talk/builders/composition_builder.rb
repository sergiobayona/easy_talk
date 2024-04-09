# frozen_string_literal: true

require_relative 'base_builder'

module EasyTalk
  module Builders
    # This class represents a builder for composing JSON schemas using the "allOf", "anyOf", or "oneOf" keywords.
    class CompositionBuilder
      extend T::Sig

      COMPOSER_TO_KEYWORD = {
        'AllOfBuilder' => 'allOf',
        'AnyOfBuilder' => 'anyOf',
        'OneOfBuilder' => 'oneOf'
      }.freeze

      sig { params(name: Symbol, type: T.untyped, _constraints: Hash).void }
      # Initializes a new instance of the CompositionBuilder class.
      #
      # @param name [Symbol] The name of the composition.
      # @param type [Class] The type of the composition.
      # @param _constraints [Hash] The constraints for the composition (not used in this method).
      def initialize(name, type, _constraints)
        @composer_type = self.class.name.split('::').last
        @name = name
        @type = type
        @context = {}
      end

      # Builds the composed JSON schema.
      #
      # @return [void]
      def build
        @context[@name.to_sym] = {
          type: 'object',
          composer_keyword => schemas
        }
      end

      # Returns the composer keyword based on the composer type.
      #
      # @return [String] The composer keyword.
      def composer_keyword
        COMPOSER_TO_KEYWORD[@composer_type]
      end

      # Returns an array of schemas for the composed JSON schema.
      #
      # @return [Array<Hash>] The array of schemas.
      def schemas
        items.map do |type|
          type.respond_to?(:schema) ? type.schema : { type: type.to_s.downcase }
        end
      end

      # Returns the items of the type.
      #
      # @return [T.untyped] The items of the type.
      def items
        @type.items
      end
    end
  end
end
