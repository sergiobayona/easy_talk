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
require_relative 'active_record_schema_builder'

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

      # Apply ActiveRecord-specific functionality if appropriate
      return unless defined?(ActiveRecord) && base.ancestors.include?(ActiveRecord::Base)

      base.extend(ActiveRecordClassMethods)
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
        method_string.end_with?('=') ? method_string.chomp('=') : method_string
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
      def as_json(_options = {})
        to_hash.merge(@additional_properties)
      end
    end

    # Module containing class-level methods for defining and accessing the schema of a model.
    module ClassMethods
      # Returns the schema for the model.
      #
      # @return [Schema] The schema for the model.
      def schema
        @schema ||= if defined?(@schema_definition) && @schema_definition
                      # Schema defined explicitly via define_schema
                      build_schema(@schema_definition)
                    elsif respond_to?(:active_record_schema_definition)
                      # ActiveRecord model without explicit schema definition
                      build_schema(active_record_schema_definition)
                    else
                      # Default case - empty schema
                      {}
                    end
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
        @schema_definition.klass = self # Pass the model class to the schema definition
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

      # Builds the schema using the provided schema definition.
      # This is the convergence point for all schema generation.
      #
      # @param schema_definition [SchemaDefinition] The schema definition.
      # @return [Schema] The validated schema.
      def build_schema(schema_definition)
        Builders::ObjectBuilder.new(schema_definition).build
      end
    end

    # Module containing ActiveRecord-specific methods for schema generation
    module ActiveRecordClassMethods
      # Gets a SchemaDefinition that's built from the ActiveRecord database schema
      #
      # @return [SchemaDefinition] A schema definition built from the database
      def active_record_schema_definition
        @active_record_schema_definition ||= ActiveRecordSchemaBuilder.new(self).build_schema_definition
      end

      # Store enhancements to be applied to the schema
      #
      # @return [Hash] The schema enhancements
      def schema_enhancements
        @schema_enhancements ||= {}
      end

      # Enhance the generated schema with additional information
      #
      # @param enhancements [Hash] The schema enhancements
      # @return [void]
      def enhance_schema(enhancements)
        @schema_enhancements = enhancements
        # Clear cached values to force regeneration
        @active_record_schema_definition = nil
        @schema = nil
        @json_schema = nil
      end
    end
  end
end
