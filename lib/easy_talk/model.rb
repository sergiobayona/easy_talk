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
require_relative 'validation_builder'

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

    # Instance methods mixed into models that include EasyTalk::Model
    module InstanceMethods
      def initialize(attributes = {})
        @additional_properties = {}
        super # Perform initial mass assignment

        # After initial assignment, instantiate nested EasyTalk::Model objects
        # Get the appropriate schema definition based on model type
        schema_def = if self.class.respond_to?(:active_record_schema_definition)
                       self.class.active_record_schema_definition
                     else
                       self.class.schema_definition
                     end

        # Only proceed if we have a valid schema definition
        return unless schema_def.respond_to?(:schema) && schema_def.schema.is_a?(Hash)

        (schema_def.schema[:properties] || {}).each do |prop_name, prop_definition|
          # Get the defined type and the currently assigned value
          defined_type = prop_definition[:type]
          current_value = public_send(prop_name)

          # Check if the type is another EasyTalk::Model and the value is a Hash
          next unless defined_type.is_a?(Class) && defined_type.include?(EasyTalk::Model) && current_value.is_a?(Hash)

          # Instantiate the nested model and assign it back
          nested_instance = defined_type.new(current_value)
          public_send("#{prop_name}=", nested_instance)
        end
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
        properties_to_include = (self.class.schema_definition.schema[:properties] || {}).keys
        return {} if properties_to_include.empty?

        properties_to_include.each_with_object({}) do |prop, hash|
          hash[prop.to_s] = send(prop)
        end
      end

      # Override as_json to include both defined and additional properties
      def as_json(_options = {})
        to_hash.merge(@additional_properties)
      end

      # Allow comparison with hashes
      def ==(other)
        case other
        when Hash
          # Convert both to comparable format for comparison
          self_hash = (self.class.schema_definition.schema[:properties] || {}).keys.each_with_object({}) do |prop, hash|
            hash[prop] = send(prop)
          end

          # Handle both symbol and string keys in the other hash
          other_normalized = other.transform_keys(&:to_sym)
          self_hash == other_normalized
        else
          super
        end
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
      def define_schema(&)
        raise ArgumentError, 'The class must have a name' unless name.present?

        @schema_definition = SchemaDefinition.new(name)
        @schema_definition.klass = self # Pass the model class to the schema definition
        @schema_definition.instance_eval(&)

        # Define accessors immediately based on schema_definition
        defined_properties = (@schema_definition.schema[:properties] || {}).keys
        attr_accessor(*defined_properties)

        # Track which properties have had validations applied
        @validated_properties ||= Set.new

        # Apply auto-validations immediately after definition
        if EasyTalk.configuration.auto_validations
          (@schema_definition.schema[:properties] || {}).each do |prop_name, prop_def|
            # Only apply validations if they haven't been applied yet
            unless @validated_properties.include?(prop_name)
              ValidationBuilder.build_validations(self, prop_name, prop_def[:type], prop_def[:constraints])
              @validated_properties.add(prop_name)
            end
          end
        end

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

      # Returns the property names defined in the schema
      #
      # @return [Array<Symbol>] Array of property names as symbols
      def properties
        (@schema_definition&.schema&.dig(:properties) || {}).keys
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
