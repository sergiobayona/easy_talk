# frozen_string_literal: true
# typed: true

module EasyTalk
  # Shared methods for JSON Schema generation.
  #
  # This module provides common functionality for building JSON schemas,
  # including $schema and $id resolution. It is included in both
  # EasyTalk::Model and EasyTalk::Schema to avoid code duplication.
  #
  # @note Classes including this module must define:
  #   - `name` - The class name (used in ref_template)
  #   - `schema` - The built schema hash (used in json_schema)
  #   - `@schema_definition` - Instance variable with schema metadata
  #
  module SchemaMethods
    # Returns the reference template for the model.
    #
    # @return [String] The reference template for the model.
    def ref_template
      "#/$defs/#{name}"
    end

    # Returns the JSON schema for the model.
    # This is the final output that includes the $schema keyword if configured.
    #
    # @return [Hash] The JSON schema for the model.
    def json_schema
      @json_schema ||= build_json_schema
    end

    private

    # Builds the final JSON schema with optional $schema and $id keywords.
    #
    # @return [Hash] The JSON schema.
    def build_json_schema
      result = schema.as_json
      schema_uri = resolve_schema_uri
      id_uri = resolve_schema_id

      prefix = {}
      prefix['$schema'] = schema_uri if schema_uri
      prefix['$id'] = id_uri if id_uri

      return result if prefix.empty?

      prefix.merge(result)
    end

    # Resolves the schema URI from per-model setting or global config.
    #
    # @return [String, nil] The schema URI.
    def resolve_schema_uri
      model_version = @schema_definition&.schema&.dig(:schema_version)

      if model_version
        return nil if model_version == :none

        Configuration::SCHEMA_VERSIONS[model_version] || model_version.to_s
      else
        EasyTalk.configuration.schema_uri
      end
    end

    # Resolves the schema ID from per-model setting or global config.
    #
    # @return [String, nil] The schema ID.
    def resolve_schema_id
      model_id = @schema_definition&.schema&.dig(:schema_id)

      if model_id
        return nil if model_id == :none

        model_id.to_s
      else
        EasyTalk.configuration.schema_id
      end
    end
  end
end
