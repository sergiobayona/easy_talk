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
require_relative 'validation_builder'
require_relative 'error_formatter'

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
      base.extend(ClassMethods)

      base.include ActiveModel::API
      base.include ActiveModel::Validations
      base.extend ActiveModel::Callbacks
      base.include(InstanceMethods)
      base.include(ErrorFormatter::InstanceMethods)
    end

    # Instance methods mixed into models that include EasyTalk::Model
    module InstanceMethods
      def initialize(attributes = {})
        @additional_properties = {}
        # Normalize keys to symbols to track provided attributes
        provided_keys = attributes.keys.to_set(&:to_sym)

        super # Perform initial mass assignment

        # After initial assignment, instantiate nested EasyTalk::Model objects
        schema_def = self.class.schema_definition

        # Only proceed if we have a valid schema definition
        return unless schema_def.respond_to?(:schema) && schema_def.schema.is_a?(Hash)

        (schema_def.schema[:properties] || {}).each do |prop_name, prop_definition|
          # Get the defined type and the currently assigned value
          defined_type = prop_definition[:type]
          nilable_type = defined_type.respond_to?(:nilable?) && defined_type.nilable?

          # Only apply default if attribute was NOT provided at all
          unless provided_keys.include?(prop_name)
            default_value = prop_definition.dig(:constraints, :default)
            public_send("#{prop_name}=", default_value) unless default_value.nil?
          end

          # Re-read current_value after potential default assignment
          current_value = public_send(prop_name)

          next if nilable_type && current_value.nil?

          defined_type = T::Utils::Nilable.get_underlying_type(defined_type) if nilable_type

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
        return super unless self.class.additional_properties_allowed?

        method_string = method_name.to_s
        method_string.end_with?('=') || @additional_properties.key?(method_string) || super
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

      # to_h includes both defined and additional properties
      def to_h
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
      include SchemaMethods

      # Returns the schema for the model.
      #
      # @return [Schema] The schema for the model.
      def schema
        @schema ||= if defined?(@schema_definition) && @schema_definition
                      build_schema(@schema_definition)
                    else
                      {}
                    end
      end

      # Define the schema for the model using the provided block.
      #
      # @param options [Hash] Options for schema definition
      # @option options [Boolean, Symbol, Class] :validations Controls validation behavior:
      #   - true: Enable validations using the configured adapter (default behavior)
      #   - false: Disable validations for this model
      #   - :none: Use the NoneAdapter (no validations)
      #   - :active_model: Use the ActiveModelAdapter
      #   - CustomAdapter: Use a custom adapter class
      # @yield The block to define the schema.
      # @raise [ArgumentError] If the class does not have a name.
      #
      # @example Disable validations for a model
      #   define_schema(validations: false) do
      #     property :name, String
      #   end
      #
      # @example Use a custom adapter
      #   define_schema(validations: MyCustomAdapter) do
      #     property :name, String
      #   end
      def define_schema(options = {}, &)
        raise ArgumentError, 'The class must have a name' unless name.present?

        @schema_definition = SchemaDefinition.new(name)
        @schema_definition.klass = self # Pass the model class to the schema definition
        @schema_definition.instance_eval(&)

        # Store validation options for this model
        @validation_options = normalize_validation_options(options)

        # Define accessors immediately based on schema_definition
        defined_properties = (@schema_definition.schema[:properties] || {}).keys
        attr_accessor(*defined_properties)

        # Track which properties have had validations applied
        @validated_properties ||= Set.new

        # Apply validations using the adapter system
        apply_schema_validations

        @schema_definition
      end

      private

      # Normalize validation options from various input formats.
      #
      # @param options [Hash] The options hash from define_schema
      # @return [Hash] Normalized options with :enabled and :adapter keys
      def normalize_validation_options(options)
        validations = options.fetch(:validations, nil)

        case validations
        when nil
          # Use global configuration
          { enabled: EasyTalk.configuration.auto_validations,
            adapter: EasyTalk.configuration.validation_adapter }
        when false
          # Explicitly disabled
          { enabled: false, adapter: :none }
        when true
          # Explicitly enabled with configured adapter
          { enabled: true, adapter: EasyTalk.configuration.validation_adapter }
        when Symbol, Class
          # Specific adapter specified
          { enabled: true, adapter: validations }
        else
          raise ArgumentError, "Invalid validations option: #{validations.inspect}. " \
                               "Expected true, false, Symbol, or Class."
        end
      end

      # Apply validations to all schema properties using the configured adapter.
      #
      # @return [void]
      def apply_schema_validations
        return unless @validation_options[:enabled]

        adapter = ValidationAdapters::Registry.resolve(@validation_options[:adapter])

        (@schema_definition.schema[:properties] || {}).each do |prop_name, prop_def|
          # Skip if already validated
          next if @validated_properties.include?(prop_name)

          # Skip if property has validate: false
          next if prop_def[:constraints][:validate] == false

          adapter.build_validations(self, prop_name, prop_def[:type], prop_def[:constraints])
          @validated_properties.add(prop_name)
        end
      end

      public

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
  end
end
