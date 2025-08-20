# frozen_string_literal: true

require 'json'
require_relative 'builders/integer_builder'
require_relative 'builders/number_builder'
require_relative 'builders/boolean_builder'
require_relative 'builders/null_builder'
require_relative 'builders/string_builder'
require_relative 'builders/temporal_builder'
require_relative 'builders/composition_builder'
require_relative 'builders/typed_array_builder'
require_relative 'builders/union_builder'

# EasyTalk module provides a DSL for building JSON Schema definitions.
#
# This module contains classes and utilities for easily creating valid JSON Schema
# documents with a Ruby-native syntax. The `Property` class serves as the main entry
# point for defining schema properties.
#
# @example Basic property definition
#   property = EasyTalk::Property.new(:name, String, minLength: 3, maxLength: 50)
#   property.build  # => {"type"=>"string", "minLength"=>3, "maxLength"=>50}
#
# @example Using with nilable types
#   nilable_prop = EasyTalk::Property.new(:optional_field, T::Types::Union.new(String, NilClass))
#   nilable_prop.build  # => {"type"=>["string", "null"]}
#
# @see EasyTalk::Property
# @see https://json-schema.org/ JSON Schema Documentation
module EasyTalk
  # Property class for building a JSON schema property.
  #
  # This class handles the conversion from Ruby types to JSON Schema property definitions,
  # and provides support for common constraints like minimum/maximum values, string patterns,
  # and custom validators.
  class Property
    extend T::Sig

    # @return [Symbol] The name of the property
    attr_reader :name

    # @return [Object] The type definition of the property
    attr_reader :type

    # @return [Hash<Symbol, Object>] Additional constraints applied to the property
    attr_reader :constraints

    # Mapping of Ruby type names to their corresponding schema builder classes.
    # Each builder knows how to convert a specific Ruby type to JSON Schema.
    #
    # @api private
    TYPE_TO_BUILDER = {
      'String' => Builders::StringBuilder,
      'Integer' => Builders::IntegerBuilder,
      'Float' => Builders::NumberBuilder,
      'BigDecimal' => Builders::NumberBuilder,
      'T::Boolean' => Builders::BooleanBuilder,
      'TrueClass' => Builders::BooleanBuilder,
      'NilClass' => Builders::NullBuilder,
      'Date' => Builders::TemporalBuilder::DateBuilder,
      'DateTime' => Builders::TemporalBuilder::DatetimeBuilder,
      'Time' => Builders::TemporalBuilder::TimeBuilder,
      'anyOf' => Builders::CompositionBuilder::AnyOfBuilder,
      'allOf' => Builders::CompositionBuilder::AllOfBuilder,
      'oneOf' => Builders::CompositionBuilder::OneOfBuilder,
      'T::Types::TypedArray' => Builders::TypedArrayBuilder,
      'T::Types::Union' => Builders::UnionBuilder
    }.freeze

    # Initializes a new instance of the Property class.
    #
    # @param name [Symbol] The name of the property
    # @param type [Object] The type of the property (Ruby class, string name, or Sorbet type)
    # @param constraints [Hash<Symbol, Object>] Additional constraints for the property
    #   (e.g., minLength, pattern, format)
    #
    # @example String property with constraints
    #   Property.new(:username, 'String', minLength: 3, maxLength: 20, pattern: '^[a-z0-9_]+$')
    #
    # @example Integer property with range
    #   Property.new(:age, 'Integer', minimum: 0, maximum: 120)
    #
    # @raise [ArgumentError] If the property type is missing or empty
    sig do
      params(name: Symbol, type: T.any(String, Object),
             constraints: T::Hash[Symbol, T.untyped]).void
    end
    def initialize(name, type = nil, constraints = {})
      @name = name
      @type = type
      @constraints = constraints
      if type.nil? || (type.respond_to?(:empty?) && type.is_a?(String) && type.strip.empty?)
        raise ArgumentError,
              'property type is missing'
      end
      raise ArgumentError, 'property type is not supported' if type.is_a?(Array) && type.empty?
    end

    # Builds the property schema based on its type and constraints.
    #
    # This method handles different types of properties:
    # - Nilable types (can be null)
    # - Types with dedicated builders
    # - Types that implement their own schema method
    # - Default fallback to 'object' type
    #
    # @return [Hash] The complete JSON Schema property definition
    #
    # @example Simple string property
    #   property = Property.new(:name, 'String')
    #   property.build  # => {"type"=>"string"}
    #
    # @example Complex nested schema
    #   address = Address.new  # A class with a .schema method
    #   property = Property.new(:shipping_address, address, description: "Shipping address")
    #   property.build  # => Address schema merged with the description constraint
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

    # Converts the property definition to a JSON-compatible format.
    #
    # This method enables seamless integration with Ruby's JSON library.
    #
    # @param _args [Array] Optional arguments passed to #as_json (ignored)
    # @return [Hash] The JSON-compatible representation of the property schema
    #
    # @see #build
    # @see https://ruby-doc.org/stdlib-2.7.2/libdoc/json/rdoc/JSON.html#as_json-method
    def as_json(*_args)
      build.as_json
    end

    # Returns the builder class associated with the property type.
    #
    # The builder is responsible for converting the Ruby type to a JSON Schema type.
    #
    # @return [Class, nil] The builder class for this property's type, or nil if no dedicated builder exists
    # @see #find_builder_for_type
    def builder
      @builder ||= find_builder_for_type
    end

    private

    # Finds the appropriate builder for the current type.
    #
    # First checks if there's a builder for the class name, then falls back
    # to checking if there's a builder for the type's name (if it responds to :name).
    #
    # @return [Class, nil] The builder class for this type, or nil if none matches
    # @api private
    def find_builder_for_type
      TYPE_TO_BUILDER[type.class.name.to_s] ||
        (type.respond_to?(:name) ? TYPE_TO_BUILDER[type.name.to_s] : nil)
    end

    # Determines if the type is nilable (can be nil).
    #
    # A type is nilable if it's a union type that includes NilClass.
    # This is typically represented as T.nilable(Type) in Sorbet.
    #
    # @return [Boolean] true if the type is nilable, false otherwise
    # @api private
    def nilable_type?
      return false unless type.respond_to?(:types)
      return false unless type.types.all? { |t| t.respond_to?(:raw_type) }

      type.types.any? { |t| t.raw_type == NilClass }
    end

    # Builds a schema for a nilable type, which can be either the actual type or null.
    #
    # @return [Hash] A schema with both the actual type and null type
    # @api private
    # @example
    #   # For a T.nilable(String) type:
    #   {"type"=>["string", "null"]}
    def build_nilable_schema
      # Extract the non-nil type from the Union
      actual_type = T::Utils::Nilable.get_underlying_type(type)

      return { type: 'null' } unless actual_type

      # Create a property with the actual type
      non_nil_schema = Property.new(name, actual_type, constraints).build

      # Merge the types into an array
      non_nil_schema.merge(
        type: [non_nil_schema[:type], 'null'].compact
      )
    end
  end
end
