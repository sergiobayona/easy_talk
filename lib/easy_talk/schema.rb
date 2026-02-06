# frozen_string_literal: true
# typed: true

require 'json'
require 'active_support'
require 'active_support/core_ext'
require 'active_support/time'
require 'active_support/concern'
require 'active_support/json'
require_relative 'builders/object_builder'
require_relative 'schema_definition'

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
      # Initialize the schema object with attributes.
      #
      # @param attributes [Hash] The attributes to set
      def initialize(attributes = {})
        @additional_properties = {}
        schema_def = self.class.schema_definition

        return unless schema_def.respond_to?(:schema) && schema_def.schema.is_a?(Hash)

        (schema_def.schema[:properties] || {}).each do |prop_name, prop_definition|
          value = attributes[prop_name] || attributes[prop_name.to_s]

          # Handle default values
          if value.nil? && !attributes.key?(prop_name) && !attributes.key?(prop_name.to_s)
            default_value = prop_definition.dig(:constraints, :default)
            value = default_value unless default_value.nil?
          end

          # Handle nested EasyTalk::Schema or EasyTalk::Model objects
          defined_type = prop_definition[:type]
          nilable_type = defined_type.respond_to?(:nilable?) && defined_type.nilable?
          defined_type = T::Utils::Nilable.get_underlying_type(defined_type) if nilable_type

          if defined_type.is_a?(Class) &&
             (defined_type.include?(EasyTalk::Schema) || defined_type.include?(EasyTalk::Model)) &&
             value.is_a?(Hash)
            value = defined_type.new(value)
          end

          instance_variable_set("@#{prop_name}", value)
        end
      end

      # Convert defined properties to a hash.
      #
      # @return [Hash] The properties as a hash
      def to_hash
        properties_to_include = (self.class.schema_definition.schema[:properties] || {}).keys
        return {} if properties_to_include.empty?

        properties_to_include.each_with_object({}) do |prop, hash|
          hash[prop.to_s] = send(prop)
        end
      end

      # Convert to JSON-compatible hash including additional properties.
      #
      # @param _options [Hash] JSON options (ignored)
      # @return [Hash] The combined hash
      def as_json(_options = {})
        to_hash.merge(@additional_properties)
      end

      # Convert to hash including additional properties.
      #
      # @return [Hash] The combined hash
      def to_h
        to_hash.merge(@additional_properties)
      end

      # Allow comparison with hashes.
      #
      # @param other [Object] The object to compare with
      # @return [Boolean] True if equal
      def ==(other)
        case other
        when Hash
          self_hash = (self.class.schema_definition.schema[:properties] || {}).keys.each_with_object({}) do |prop, hash|
            hash[prop] = send(prop)
          end
          other_normalized = other.transform_keys(&:to_sym)
          self_hash == other_normalized
        else
          super
        end
      end
    end

    # Class methods for schema-only models.
    module ClassMethods
      include SchemaMethods

      # Returns the schema for the model.
      #
      # @return [Hash] The schema for the model.
      def schema
        @schema ||= if defined?(@schema_definition) && @schema_definition
                      build_schema(@schema_definition)
                    else
                      {}
                    end
      end

      # Define the schema for the model using the provided block.
      # Unlike EasyTalk::Model, this does NOT apply any validations.
      #
      # @yield The block to define the schema.
      # @raise [ArgumentError] If the class does not have a name.
      def define_schema(&)
        raise ArgumentError, 'The class must have a name' if name.blank?

        @schema_definition = SchemaDefinition.new(name)
        @schema_definition.klass = self
        @schema_definition.instance_eval(&)

        # Define accessors for all properties
        defined_properties = (@schema_definition.schema[:properties] || {}).keys
        attr_accessor(*defined_properties)

        # NO validations are applied - this is schema-only

        @schema_definition
      end

      # Returns the schema definition for the model.
      #
      # @return [SchemaDefinition] The schema definition.
      def schema_definition
        @schema_definition ||= {}
      end

      # Returns an ActiveModel::Type adapter for this schema class.
      #
      # @return [EasyTalk::ActiveModelType]
      def to_type
        EasyTalk::ActiveModelType.new(self)
      end

      # Check if additional properties are allowed.
      #
      # @return [Boolean] True if additional properties are allowed.
      def additional_properties_allowed?
        @schema_definition&.schema&.fetch(:additional_properties, false)
      end

      # Returns the property names defined in the schema.
      #
      # @return [Array<Symbol>] Array of property names as symbols.
      def properties
        (@schema_definition&.schema&.dig(:properties) || {}).keys
      end

      private

      # Builds the schema using the provided schema definition.
      #
      # @param schema_definition [SchemaDefinition] The schema definition.
      # @return [Hash] The built schema.
      def build_schema(schema_definition)
        Builders::ObjectBuilder.new(schema_definition).build
      end
    end
  end
end
