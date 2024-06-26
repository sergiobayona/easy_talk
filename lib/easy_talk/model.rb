# frozen_string_literal: true

require 'json'
require 'active_support'
require 'active_support/core_ext'
require 'active_support/time'
require 'active_support/concern'
require 'active_support/json'
require 'active_model'
require 'json_schemer'
require_relative 'schema_errors_mapper'
require_relative 'builders/object_builder'
require_relative 'schema_definition'

module EasyTalk
  # The `Model` module is a mixin that provides functionality for defining and accessing the schema of a model.
  #
  # It includes methods for defining the schema, retrieving the schema definition,
  # and generating the JSON schema for the model.
  #
  # Example usage:
  #
  #   class Person
  #     include EasyTalk::Model
  #
  #     define_schema do
  #       property :name, String, description: 'The person\'s name'
  #       property :age, Integer, description: 'The person\'s age'
  #     end
  #   end
  #
  #   Person.json_schema #=> returns the JSON schema for Person
  #   jim = Person.new(name: 'Jim', age: 30)
  #   jim.valid? #=> returns true
  #
  # @see SchemaDefinition
  module Model
    def self.included(base)
      base.include ActiveModel::API # Include ActiveModel::API in the class including EasyTalk::Model
      base.include ActiveModel::Validations
      base.extend ActiveModel::Callbacks
      base.validates_with SchemaValidator
      base.extend(ClassMethods)
    end

    class SchemaValidator < ActiveModel::Validator
      def validate(record)
        result = schema_validation(record)
        result.errors.each do |key, error_msg|
          record.errors.add key.to_sym, error_msg
        end
      end

      def schema_validation(record)
        schema = JSONSchemer.schema(record.class.json_schema)
        errors = schema.validate(record.properties)
        SchemaErrorsMapper.new(errors)
      end
    end

    # Returns the properties of the model as a hash with symbolized keys.
    def properties
      as_json.symbolize_keys!
    end

    # Module containing class-level methods for defining and accessing the schema of a model.
    module ClassMethods
      # Returns the schema for the model.
      #
      # @return [Schema] The schema for the model.
      def schema
        @schema ||= build_schema(schema_definition)
      end

      # Returns true if the class inherits a schema.
      #
      # @return [Boolean] `true` if the class inherits a schema, `false` otherwise.
      def inherits_schema?
        false
      end

      # Returns the reference template for the model.
      #
      # @return [String] The reference template for the model.
      def ref_template
        "#/$defs/#{name}"
      end

      # Returns the name of the model as a human-readable function name.
      #
      # @return [String] The human-readable function name of the model.
      def function_name
        name.humanize.titleize
      end

      def properties
        @properties ||= begin
          return unless schema[:properties].present?

          schema[:properties].keys.map(&:to_sym)
        end
      end

      # Returns the JSON schema for the model.
      #
      # @return [Hash] The JSON schema for the model.
      def json_schema
        @json_schema ||= schema.as_json
      end

      # Define the schema for the model using the provided block.
      #
      # @yield The block to define the schema.
      # @raise [ArgumentError] If the class does not have a name.
      def define_schema(&block)
        raise ArgumentError, 'The class must have a name' unless name.present?

        @schema_definition = SchemaDefinition.new(name)
        @schema_definition.instance_eval(&block)
        attr_accessor(*properties)

        @schema_defintion
      end

      # Returns the unvalidated schema definition for the model.
      #
      # @return [SchemaDefinition] The unvalidated schema definition for the model.
      def schema_definition
        @schema_definition ||= {}
      end

      private

      # Builds the schema using the provided schema definition.
      #
      # @param schema_definition [SchemaDefinition] The schema definition.
      # @return [Schema] The validated schema.
      def build_schema(schema_definition)
        Builders::ObjectBuilder.new(schema_definition).build
      end
    end
  end
end
