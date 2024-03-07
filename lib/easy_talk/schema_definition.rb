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
      @schema_definition[:properties].merge!(name => constraints.merge!(type:))
    end
  end
end
