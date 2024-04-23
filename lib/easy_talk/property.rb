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
require_relative 'builders/any_of_builder'
require_relative 'builders/all_of_builder'
require_relative 'builders/one_of_builder'
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
      'anyOf' => Builders::AnyOfBuilder,
      'allOf' => Builders::AllOfBuilder,
      'oneOf' => Builders::OneOfBuilder,
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
      return type.respond_to?(:schema) ? type.schema : 'object' unless builder

      args = builder.collection_type? ? [name, type, constraints] : [name, constraints]
      builder.new(*args).build
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
      TYPE_TO_BUILDER[type.class.name.to_s] || TYPE_TO_BUILDER[type.name.to_s]
    end
  end
end
