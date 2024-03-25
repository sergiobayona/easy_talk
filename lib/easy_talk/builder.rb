# frozen_string_literal: true

require_relative 'property'
require_relative 'builders/object_builder'

module EasyTalk
  # The Builder class is responsible for building a schema for a class.
  class Builder
    extend T::Sig

    sig { params(schema_definition: SchemaDefinition).void }
    # Initializes a new instance of the Builder class.
    #
    # @param schema_definition [SchemaDefinition] The schema definition.
    def initialize(schema_definition)
      @schema_definition = schema_definition
    end

    sig { returns(Hash) }
    # Retrieves the schema document.
    #
    # @return [Hash] The schema document.
    def schema
      @schema = schema_document
    end

    sig { returns(String) }
    # Returns the JSON representation of the schema document.
    #
    # @return [String] The JSON schema.
    def json_schema
      @json_schema ||= schema_document.to_json
    end

    sig { returns(Hash) }
    # Returns the schema document, building it if necessary.
    #
    # @return [Hash] The schema document.
    def schema_document
      @schema_document ||= build_schema
    end

    sig { returns(Hash) }
    # Builds the schema using the schema definition.
    #
    # Returns the built schema.
    def build_schema
      Builders::ObjectBuilder.new(@schema_definition).build
    end
  end
end
