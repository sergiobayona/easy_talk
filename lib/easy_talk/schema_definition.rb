# frozen_string_literal: true

require_relative 'keywords'

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
    def property(name, type, constraints={}, &blk)
      @schema[:properties] ||= {}

      if block_given?
        # Create a clean copy of constraints to avoid mutation
        original_constraints = constraints.dup

        # Create property schema with nested properties
        property_schema = SchemaDefinition.new(name)
        property_schema.instance_eval(&blk)

        # Set the properties separately from constraints
        @schema[:properties][name] = {
          type: type,
          constraints: original_constraints,
          properties: property_schema
        }
      else
        @schema[:properties][name] = { type: type, constraints: constraints }
      end
    end

    def optional?
      @schema[:optional]
    end
  end
end
