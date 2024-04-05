# frozen_string_literal: true

require 'pry-byebug'
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

    def initialize(name)
      @schema = {}
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

    sig { params(name: Symbol, type: T.untyped, constraints: T.untyped).void }
    def property(name, type, **constraints)
      @schema[:properties] ||= {}
      @schema[:properties][name] = { type:, constraints: }
    end
  end
end
