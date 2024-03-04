# frozen_string_literal: true

require_relative 'property'

module EsquemaBase
  # The Builder class is responsible for building a schema for a class.
  class Builder
    extend T::Sig
    OBJECT_KEYWORDS = %i[title description type properties required].freeze

    sig { params(schema_definition: T::Hash[Symbol, T.untyped]).returns(Hash) }
    def self.build_schema(schema_definition)
      builder = new(schema_definition)
      builder.schema
    end

    sig { params(schema_definition: T::Hash[Symbol, T.untyped]).void }
    def initialize(schema_definition)
      @schema_definition = schema_definition
      @properties = {}
      @required_properties = []
    end

    sig { returns(Hash) }
    def schema
      @schema ||= schema_document
    end

    sig { returns(String) }
    def json_schema
      @json_schema ||= schema_document.to_json
    end

    sig { returns(Hash) }
    def schema_document
      OBJECT_KEYWORDS.each_with_object({}) do |keyword, hash|
        value = send("build_#{keyword}")
        next if value.blank?

        hash[keyword] = value
      end.compact
    end

    sig { returns(T.nilable(String)) }
    def build_title
      @schema_definition[:title]
    end

    sig { returns(T.nilable(String)) }
    def build_description
      @schema_definition[:description]
    end

    sig { returns(String) }
    def build_type
      @schema_definition[:type] || 'object'
    end

    sig { returns(T::Hash[String, Property]) }
    def build_properties
      properties.each_with_object({}) do |(property_name, options), hash|
        type = options.delete(:type)
        @required_properties << property_name unless options[:optional]
        hash[property_name] = Property.new(property_name, type, options)
      end
    end

    sig { returns(T::Hash[Symbol, T::Hash[Symbol, String]]) }
    def properties
      @schema_definition[:properties] || {}
    end

    sig { returns(T::Array[String]) }
    def build_required
      @required_properties
    end
  end
end
