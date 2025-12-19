# frozen_string_literal: true

require_relative 'keywords'
require_relative 'types/composer'
require_relative 'validation_builder'

module EasyTalk
  #
  #= EasyTalk \SchemaDefinition
  # SchemaDefinition provides the methods for defining a schema within the define_schema block.
  # The @schema is a hash that contains the unvalidated schema definition for the model.
  # A SchemaDefinition instanace is the passed to the Builder.build_schema method to validate and compile the schema.
  class SchemaDefinition
    extend T::Sig
    extend T::AnyOf
    extend T::OneOf
    extend T::AllOf

    attr_reader :name, :schema
    attr_accessor :klass # Add accessor for the model class

    def initialize(name, schema = {})
      @schema = schema
      @schema[:additional_properties] = false unless schema.key?(:additional_properties)
      @name = name
      @klass = nil # Initialize klass to nil
      @property_naming_strategy = EasyTalk.configuration.property_naming_strategy
    end

    EasyTalk::KEYWORDS.each do |keyword|
      define_method(keyword) do |*values|
        @schema[keyword] = values.size > 1 ? values : values.first
      end
    end

    def compose(*subschemas)
      @schema[:subschemas] ||= []
      @schema[:subschemas] += subschemas
    end

    def property(name, type, constraints = {}, &)
      constraints[:as] ||= @property_naming_strategy.call(name)
      validate_property_name(constraints[:as])
      @schema[:properties] ||= {}

      if block_given?
        raise ArgumentError,
              'Block-style sub-schemas are no longer supported. Use class references as types instead.'
      end

      @schema[:properties][name] = { type:, constraints: }
    end

    def validate_property_name(name)
      return if name.to_s.match?(/^[A-Za-z_][A-Za-z0-9_]*$/)

      message = "Invalid property name '#{name}'. Must start with letter/underscore " \
        'and contain only letters, numbers, underscores'
      raise InvalidPropertyNameError, message
    end

    def optional?
      @schema[:optional]
    end

    # Helper method for nullable and optional properties
    def nullable_optional_property(name, type, constraints = {})
      # Ensure type is nilable
      nilable_type = if type.respond_to?(:nilable?) && type.nilable?
                       type
                     else
                       T.nilable(type)
                     end

      # Ensure constraints include optional: true
      constraints = constraints.merge(optional: true)

      # Call standard property method
      property(name, nilable_type, constraints)
    end

    def property_naming_strategy(strategy)
      @property_naming_strategy = EasyTalk::NamingStrategies.derive_strategy(strategy)
    end
  end
end
