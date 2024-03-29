# frozen_string_literal: true

require 'json'
require 'active_support'
require 'active_support/core_ext'
require 'active_support/time'
require 'active_support/concern'
require 'active_support/json'
require_relative 'builder'
require_relative 'schema_definition'

module EasyTalk
  # The Model module can be included in a class to add JSON schema definition and generation support.
  module Model
    def self.included(base)
      base.extend(ClassMethods)

      base.singleton_class.instance_eval do
        define_method(:inherited) do |subclass|
          super(subclass)
          subclass.extend(SubclassExtension)
        end
      end
    end

    # This module provides extension methods for subclasses with schema definitions.
    module SubclassExtension
      # Returns true if the class inherits a schema.
      def inherits_schema?
        true
      end

      # Returns the superclass that the class inherits from.
      def inherits_from
        superclass
      end
    end

    # Module containing class-level methods for defining and accessing the schema of a model.
    #
    # This module provides methods for defining and accessing the JSON schema of a model.
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
    # @see Builder
    module ClassMethods
      def schema
        @schema ||= {}
      end

      def inherits_schema?
        false
      end

      def ref_template
        "#/$defs/#{name}"
      end

      # Returns the JSON schema for the model.
      def json_schema
        @json_schema ||= schema.to_json
      end

      # Define the schema using the provided block.
      def define_schema(&block)
        raise ArgumentError, 'The class must have a name' unless name.present?

        schema_definition
        definition = SchemaDefinition.new(self, @schema_definition)
        definition.instance_eval(&block)
        @schema = Builder.new(definition).schema
      end

      # Returns the schema definition.
      # The schema_definition is a hash that contains the unvalidated schema definition for the model.
      # It is then passed to the Builder.build_schema method to validate and compile the schema.
      def schema_definition
        @schema_definition ||= {}
      end
    end
  end
end
