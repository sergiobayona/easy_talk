# frozen_string_literal: true

require 'json'
require 'active_support'
require 'active_support/core_ext'
require 'active_support/time'
require 'active_support/concern'
require 'active_support/json'
require 'json-schema'
require_relative 'builders/object_builder'
require_relative 'schema_definition'

module EasyTalk
  # The Model module can be included in a class to add JSON schema definition and generation support.
  module Model
    # The `Model` module is a mixin that provides functionality for defining and accessing the schema of a model.
    #
    # It includes methods for defining the schema, retrieving the schema definition,
    # and generating the JSON schema for the model.
    #
    # Example usage:
    #
    #   class MyModel
    #     extend ClassMethods
    #
    #     define_schema do
    #       # schema definition goes here
    #     end
    #   end
    #
    #   MyModel.json_schema #=> returns the JSON schema for MyModel
    #
    #   MyModel.schema_definition #=> returns the unvalidated schema definition for MyModel
    #
    #   MyModel.ref_template #=> returns the reference template for MyModel
    #
    #   MyModel.inherits_schema? #=> returns false
    #
    #   MyModel.schema #=> returns the validated schema for MyModel
    #
    #   MyModel.schema_definition #=> returns the unvalidated schema definition for MyModel
    #
    #   MyModel.json_schema #=> returns the JSON schema for MyModel
    #
    # @see SchemaDefinition
    #
    def self.included(base)
      base.extend(ClassMethods)
    end

    # Initializes a new instance of the Model class.
    #
    # @param properties [Hash] The properties to set for the instance.
    def initialize(properties = {})
      properties.each do |key, value|
        instance_variable_set("@#{key}", value)
        self.class.class_eval { attr_reader key }
      end
    end

    # Checks if the model is valid.
    #
    # This method calls the `validate_json` class method on the current class,
    # passing the `properties` as the argument.
    #
    # @return [Boolean] true if the model is valid, false otherwise.
    def valid?
      self.class.validate_json(properties)
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

      # Validates the given JSON against the model's JSON schema.
      #
      # @param json [Hash] The JSON to validate.
      # @return [Boolean] `true` if the JSON is valid, `false` otherwise.
      def validate_json(json)
        JSON::Validator.validate(json_schema, json)
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
