# frozen_string_literal: true
# typed: true

require 'json'
require 'active_support'
require 'active_support/core_ext'
require 'active_support/time'
require 'active_support/concern'
require 'active_support/json'
require_relative 'schema_base'

module EasyTalk
  # A lightweight module for schema generation without ActiveModel validations.
  #
  # Use this module when you need JSON Schema generation without the overhead
  # of ActiveModel validations. This is ideal for:
  # - API documentation and OpenAPI spec generation
  # - Schema-first design where validation happens elsewhere
  # - High-performance scenarios where validation overhead is unwanted
  # - Generating schemas for external systems
  #
  # Unlike EasyTalk::Model, this module does NOT include ActiveModel::API or
  # ActiveModel::Validations, so instances will not respond to `valid?` or have
  # validation errors.
  #
  # @example Basic usage
  #   class ApiContract
  #     include EasyTalk::Schema
  #
  #     define_schema do
  #       title 'API Contract'
  #       property :name, String, min_length: 2
  #       property :age, Integer, minimum: 0
  #     end
  #   end
  #
  #   ApiContract.json_schema  # => { "type" => "object", ... }
  #   contract = ApiContract.new(name: 'Test', age: 25)
  #   contract.name # => 'Test'
  #   contract.valid? # => NoMethodError (no ActiveModel)
  #
  # @see EasyTalk::Model For a full-featured module with validations
  #
  module Schema
    def self.included(base)
      base.extend(ClassMethods)
      base.include(InstanceMethods)
    end

    # Instance methods for schema-only models.
    module InstanceMethods
      include SchemaBase::InstanceMethods

      # Initialize the schema object with attributes.
      # Performs manual attribute assignment (no ActiveModel) then applies
      # defaults and nested model instantiation via the shared base.
      #
      # @param attributes [Hash] The attributes to set
      def initialize(attributes = {})
        @additional_properties = {}
        provided_keys = Set.new

        schema_def = self.class.schema_definition
        assign_schema_attributes(attributes, schema_def, provided_keys) if schema_def.respond_to?(:schema) && schema_def.schema.is_a?(Hash)

        initialize_schema_properties(provided_keys)
      end

      private

      def assign_schema_attributes(attributes, schema_def, provided_keys)
        (schema_def.schema[:properties] || {}).each_key do |prop_name|
          if attributes.key?(prop_name)
            provided_keys << prop_name
            public_send("#{prop_name}=", attributes[prop_name])
          elsif attributes.key?(prop_name.to_s)
            provided_keys << prop_name
            public_send("#{prop_name}=", attributes[prop_name.to_s])
          end
        end
      end
    end

    # Class methods for schema-only models.
    module ClassMethods
      include SchemaBase::ClassMethods
    end
  end
end
