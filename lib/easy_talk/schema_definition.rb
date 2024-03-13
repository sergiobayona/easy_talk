# frozen_string_literal: true

require 'pry-byebug'
require_relative 'keywords'

module EasyTalk
  #
  #= EasyTalk \SchemaDefinition
  # SchemaDefinition provides the methods for defining a schema within the define_schema block.
  # The @schema_definition is a hash that contains the unvalidated schema definition for the model.
  # A SchemaDefinition instanace is the passed to the Builder.build_schema method to validate and compile the schema.
  class SchemaDefinition
    extend T::Sig

    attr_reader :klass, :schema_definition

    alias to_h schema_definition

    def initialize(klass, schema_definition)
      @schema_definition = schema_definition
      @klass = klass
    end

    EasyTalk::KEYWORDS.each do |keyword|
      define_method(keyword) do |*values|
        @schema_definition[keyword] = values.size > 1 ? values : values.first
      end
    end

    sig { params(name: Symbol, type: T.untyped, constraints: T.untyped).void }
    def property(name, type, **constraints)
      @schema_definition[:properties] ||= {}
      @schema_definition[:properties][name] = { type:, constraints: }
    end

    def all_of(*models)
      @schema_definition[:all_of] = process_models(models)
    end

    def one_of(*models)
      @schema_definition[:one_of] = process_models(models)
    end

    def any_of(*models)
      @schema_definition[:any_of] = process_models(models)
    end

    private

    def process_models(models)
      models.map do |model|
        unless model.is_a?(Class) && model.included_modules.include?(EasyTalk::Model)
          raise ArgumentError, "Invalid argument: #{model}. Must be a class that includes EasyTalk::Model"
        end

        insert_definition(model.name.to_sym, model.schema)
        { "$ref": model.ref_template }
      end
    end

    def insert_definition(name, schema)
      @schema_definition[:defs] ||= {}
      @schema_definition[:defs][name] = schema
    end
  end
end
