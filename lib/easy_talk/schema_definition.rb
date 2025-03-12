# frozen_string_literal: true

require_relative 'keywords'
require_relative 'types/composer'

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

    def initialize(name, schema = {})
      @schema = schema
      @schema[:additional_properties] = false unless schema.key?(:additional_properties)
      @name = name
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

    sig do
      params(name: T.any(Symbol, String), type: T.untyped, constraints: T.untyped, blk: T.nilable(T.proc.void)).void
    end
    def property(name, type, constraints = {}, &blk)
      validate_property_name(name)
      @schema[:properties] ||= {}

      if block_given?
        property_schema = SchemaDefinition.new(name)
        property_schema.instance_eval(&blk)

        @schema[:properties][name] = {
          type:,
          constraints:,
          properties: property_schema
        }
      else
        @schema[:properties][name] = { type:, constraints: }
      end
    end

    def validate_property_name(name)
      return if name.to_s.match?(/^[A-Za-z_][A-Za-z0-9_]*$/)

      raise InvalidPropertyNameError,
            "Invalid property name '#{name}'. Must start with letter/underscore and contain only letters, numbers, underscores"
    end

    def optional?
      @schema[:optional]
    end

    # Helper method for nullable and optional properties
    def nullable_optional_property(name, type, constraints = {}, &blk)
      # Ensure type is nilable
      nilable_type = if type.respond_to?(:nilable?) && type.nilable?
                       type
                     else
                       T.nilable(type)
                     end

      # Ensure constraints include optional: true
      constraints = constraints.merge(optional: true)

      # Call standard property method
      property(name, nilable_type, constraints, &blk)
    end
  end
end
