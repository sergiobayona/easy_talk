# frozen_string_literal: true

require_relative 'property'
require_relative 'builders/object_builder'

module EasyTalk
  # The Builder class is responsible for building a schema for a class.
  class Builder
    extend T::Sig
    OBJECT_KEYWORDS = %i[title description type properties additional_properties required].freeze

    sig { params(schema_definition: SchemaDefinition).void }
    def initialize(schema_definition)
      @schema_definition = schema_definition
      @properties = {}
      @required_properties = []
    end

    sig { returns(Hash) }
    def schema
      @schema = schema_document
    end

    sig { returns(String) }
    def json_schema
      @json_schema ||= schema_document.to_json
    end

    sig { returns(Hash) }
    def schema_document
      @schema_document ||= build_schema
    end

    def build_schema
      Builders::ObjectBuilder.new(@schema_definition).build
    end
  end
end
