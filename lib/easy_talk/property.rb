# frozen_string_literal: true

require 'json'
require_relative 'builders/integer_builder'
require_relative 'builders/number_builder'
require_relative 'builders/boolean_builder'
require_relative 'builders/null_builder'
require_relative 'builders/string_builder'
require_relative 'builders/date_builder'
require_relative 'builders/datetime_builder'
require_relative 'builders/time_builder'
require_relative 'builders/composition_builder'
require_relative 'builders/typed_array_builder'
require_relative 'builders/union_builder'

# frozen_string_literal: true

# EasyTalk module provides classes for building JSON schema properties.
#
# This module contains the `Property` class, which is used to build a JSON schema property.
# It also defines a constant `TYPE_TO_BUILDER` which maps property types to their respective builders.
#
# Example usage:
#   property = EasyTalk::Property.new(:name, 'String', minLength: 3, maxLength: 50)
#   property.build
#
# @see EasyTalk::Property
module EasyTalk
  # Property class for building a JSON schema property.
  class Property
    extend T::Sig
    attr_reader :name, :type, :constraints

    TYPE_TO_BUILDER = {
      'String' => Builders::StringBuilder,
      'Integer' => Builders::IntegerBuilder,
      'Float' => Builders::NumberBuilder,
      'BigDecimal' => Builders::NumberBuilder,
      'T::Boolean' => Builders::BooleanBuilder,
      'NilClass' => Builders::NullBuilder,
      'Date' => Builders::DateBuilder,
      'DateTime' => Builders::DatetimeBuilder,
      'Time' => Builders::TimeBuilder,
      'anyOf' => Builders::CompositionBuilder::AnyOfBuilder,
      'allOf' => Builders::CompositionBuilder::AllOfBuilder,
      'oneOf' => Builders::CompositionBuilder::OneOfBuilder,
      'T::Types::TypedArray' => Builders::TypedArrayBuilder,
      'T::Types::Union' => Builders::UnionBuilder
    }.freeze

    # Initializes a new instance of the Property class.
    # @param name [Symbol] The name of the property.
    # @param type [Object] The type of the property.
    # @param constraints [Hash] The property constraints.
    # @raise [ArgumentError] If the property type is missing.
    sig do
      params(name: Symbol, type: T.any(String, Object),
             constraints: T::Hash[Symbol, T.untyped]).void
    end
    def initialize(name, type = nil, constraints = {})
      @name = name
      @type = type
      @constraints = constraints
      raise ArgumentError, 'property type is missing' if type.blank?
    end

    # Builds the property based on the specified type, constraints, and builder.
    #
    # If the type responds to the `schema` method, it returns the schema of the type.
    # Otherwise, it returns 'object'.
    #
    # If a builder is specified, it uses the builder to build the property.
    # The arguments passed to the builder depend on whether the builder is a collection type or not.
    #
    # @return [Object] The built property.
    def build
      if nilable_type?
        build_nilable_schema
      elsif builder
        args = builder.collection_type? ? [name, type, constraints] : [name, constraints]
        builder.new(*args).build
      elsif type.respond_to?(:schema)
        # merge the top-level constraints from *this* property
        # e.g. :title, :description, :default, etc
        type.schema.merge!(constraints)
      else
        'object'
      end
    end

    # Converts the object to a JSON representation.
    #
    # @param _args [Array] Optional arguments
    # @return [Hash] The JSON representation of the object
    def as_json(*_args)
      build.as_json
    end

    # Returns the builder associated with the property type.
    #
    # The builder is responsible for constructing the property based on its type.
    # It looks up the builder based on the type's class name or name.
    #
    # @return [Builder] The builder associated with the property type.
    def builder
      @builder ||= TYPE_TO_BUILDER[type.class.name.to_s] || TYPE_TO_BUILDER[type.name.to_s]
    end

    private

    def nilable_type?
      return unless type.respond_to?(:types)
      return unless type.types.all? { |t| t.respond_to?(:raw_type) }

      type.types.any? { |t| t.raw_type == NilClass }
    end

    def build_nilable_schema
      # Extract the non-nil type from the Union
      actual_type = type.types.find { |t| t != NilClass }

      # Create a property with the actual type
      non_nil_schema = Property.new(name, actual_type, constraints).build

      # Merge the types into an array
      non_nil_schema.merge(
        type: [non_nil_schema[:type], 'null']
      )
    end
  end
end
