# frozen_string_literal: true

require_relative 'collection_helpers'
require_relative '../ref_helper'

module EasyTalk
  module Builders
    # This class represents a builder for composing JSON schemas using the "allOf", "anyOf", or "oneOf" keywords.
    class CompositionBuilder
      extend CollectionHelpers
      extend T::Sig

      COMPOSER_TO_KEYWORD = {
        'AllOfBuilder' => 'allOf',
        'AnyOfBuilder' => 'anyOf',
        'OneOfBuilder' => 'oneOf'
      }.freeze

      sig { params(name: Symbol, type: T.untyped, constraints: Hash).void }
      # Initializes a new instance of the CompositionBuilder class.
      #
      # @param name [Symbol] The name of the composition.
      # @param type [Class] The type of the composition.
      # @param constraints [Hash] The constraints for the composition.
      def initialize(name, type, constraints)
        @composer_type = self.class.name.split('::').last
        @name = name
        @type = type
        @context = {}
        @constraints = constraints
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
          if EasyTalk::RefHelper.should_use_ref?(type, @constraints)
            EasyTalk::RefHelper.build_ref_schema(type, @constraints)
          elsif type.respond_to?(:schema)
            type.schema
          else
            # Map Float type to 'number' in JSON Schema
            json_type = case type.to_s
                       when 'Float', 'BigDecimal'
                         'number'
                       else
                         type.to_s.downcase
                       end
            { type: json_type }
          end
        end
      end

      # Returns the items of the type.
      #
      # @return [T.untyped] The items of the type.
      def items
        @type.items
      end

      # Builder class for AllOf composition.
      class AllOfBuilder < CompositionBuilder
      end

      # Builder class for AnyOf composition.
      class AnyOfBuilder < CompositionBuilder
      end

      # Builder class for OneOf composition.
      class OneOfBuilder < CompositionBuilder
      end
    end
  end
end
