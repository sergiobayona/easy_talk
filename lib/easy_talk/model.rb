# frozen_string_literal: true

require 'json'
require 'active_support'
require 'active_support/core_ext'
require 'active_support/time'
require 'active_support/concern'
require 'active_support/json'
require 'active_model'
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
      base.extend(ClassMethods)
      base.include(InstanceMethods)
    end

    module InstanceMethods
      def initialize(attributes = {})
        @additional_properties = {}
        super
      end

      def method_missing(method_name, *args)
        method_string = method_name.to_s
        if method_string.end_with?('=')
          property_name = method_string.chomp('=')
          if self.class.additional_properties_allowed?
            @additional_properties[property_name] = args.first
          else
            super
          end
        elsif self.class.additional_properties_allowed? && @additional_properties.key?(method_string)
          @additional_properties[method_string]
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        method_string = method_name.to_s
        property_name = method_string.end_with?('=') ? method_string.chomp('=') : method_string
        self.class.additional_properties_allowed? || super
      end

      # Add to_hash method to convert defined properties to hash
      def to_hash
        return {} unless self.class.properties

        self.class.properties.each_with_object({}) do |prop, hash|
          hash[prop.to_s] = send(prop)
        end
      end

      # Override as_json to include both defined and additional properties
      def as_json(options = {})
        to_hash.merge(@additional_properties)
      end
    end

    # Module containing class-level methods for defining and accessing the schema of a model.
    module ClassMethods
      # Returns the schema for the model.
      #
      # @return [Schema] The schema for the model.
      def schema
        @schema ||= build_schema(schema_definition)
      end

      # Returns the reference template for the model.
      #
      # @return [String] The reference template for the model.
      def ref_template
        "#/$defs/#{name}"
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

        @schema_definition
      end

      # Returns the unvalidated schema definition for the model.
      #
      # @return [SchemaDefinition] The unvalidated schema definition for the model.
      def schema_definition
        @schema_definition ||= {}
      end

      def additional_properties_allowed?
        @schema_definition&.schema&.fetch(:additional_properties, false)
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
