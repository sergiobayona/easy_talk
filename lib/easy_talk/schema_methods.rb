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
    # When prefer_external_refs is enabled and the model has a schema ID,
    # returns the external $id URI. Otherwise, returns the local $defs reference.
    #
    # @return [String] The reference template for the model.
    def ref_template
      config = EasyTalk.configuration

      # Use external ref when configured and $id available, otherwise fall back to local $defs
      schema_id = resolve_schema_id if config.prefer_external_refs
      schema_id || "#/$defs/#{name}"
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

    # Resolves the schema ID from per-model setting, auto-generation, or global config.
    # Precedence order:
    #   1. Per-model explicit schema_id (highest priority)
    #   2. Auto-generated from base_schema_uri (middle priority)
    #   3. Global schema_id (lowest priority)
    #
    # @return [String, nil] The schema ID.
    def resolve_schema_id
      model_id = @schema_definition&.schema&.dig(:schema_id)

      # Per-model explicit ID takes precedence
      if model_id
        return nil if model_id == :none

        return model_id.to_s
      end

      # Auto-generate from base_schema_uri if enabled
      config = EasyTalk.configuration
      return generate_schema_id(config.base_schema_uri, name) if config.auto_generate_ids && config.base_schema_uri && name

      # Fall back to global schema_id
      config.schema_id
    end

    # Generates a schema ID from the base URI and model name.
    # Normalizes the base URI and converts the model name to underscore case.
    #
    # @param base_uri [String] The base URI for schema IDs.
    # @param model_name [String] The model class name.
    # @return [String] The generated schema ID.
    def generate_schema_id(base_uri, model_name)
      # Normalize base URI (remove trailing slash)
      base = base_uri.to_s.chomp('/')
      # Convert model name to lowercase with underscores for URI segment
      segment = model_name.to_s.underscore
      "#{base}/#{segment}"
    end
  end
end
