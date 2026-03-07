# frozen_string_literal: true
# typed: true

require 'json'
require 'active_support'
require 'active_support/core_ext'
require 'active_support/time'
require 'active_support/concern'
require 'active_support/json'
require 'active_model'
require_relative 'schema_base'
require_relative 'validation_builder'
require_relative 'error_formatter'
require_relative 'extensions/ruby_llm_compatibility'

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
      base.extend(EasyTalk::Extensions::RubyLLMCompatibility) # Add class-level methods

      base.include ActiveModel::API
      base.include ActiveModel::Validations
      base.extend ActiveModel::Callbacks
      base.include(InstanceMethods)
      base.include(ErrorFormatter::InstanceMethods)

      # If inheriting from RubyLLM::Tool, override schema methods to use EasyTalk's schema
      return unless defined?(RubyLLM::Tool) && base < RubyLLM::Tool

      base.include(EasyTalk::Extensions::RubyLLMToolOverrides)
    end

    # Instance methods mixed into models that include EasyTalk::Model
    module InstanceMethods
      include SchemaBase::InstanceMethods

      def initialize(attributes = {})
        @additional_properties = {}
        provided_keys = attributes.keys.to_set(&:to_sym)

        super # Perform initial mass assignment via ActiveModel::API

        initialize_schema_properties(provided_keys)
      end

      # Returns a Hash representing the schema in a format compatible with RubyLLM.
      # Delegates to the class method. Required for RubyLLM's with_schema method.
      #
      # @return [Hash] The RubyLLM-compatible schema representation
      def to_json_schema
        self.class.to_json_schema
      end
    end

    # Module containing class-level methods for defining and accessing the schema of a model.
    module ClassMethods
      include SchemaBase::ClassMethods

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
        super(&)

        # Store validation options for this model
        @validation_options = normalize_validation_options(options)

        # Initialize mutex eagerly for thread-safe schema-level validation application
        @schema_level_validation_lock = Mutex.new

        # Apply validations using the adapter system
        apply_schema_validations

        @schema_definition
      end

      private

      # Reset all memoized schema state and clear previously registered
      # ActiveModel validators so a second define_schema call is never ignored.
      def clear_schema_state!
        super
        @schema_level_validations_applied = false
        @validated_properties = Set.new

        return unless @schema_definition

        reset_callbacks(:validate)
        _validators.clear
      end

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

        # Apply schema-level validations (min_properties, max_properties, dependent_required)
        apply_schema_level_validations(adapter)
      end

      # Apply schema-level validations for object-level constraints.
      # Uses double-checked locking for thread safety.
      # The mutex is initialized eagerly in define_schema.
      #
      # @param adapter [Class] The validation adapter class
      # @return [void]
      def apply_schema_level_validations(adapter)
        return if @schema_level_validations_applied

        @schema_level_validation_lock.synchronize do
          return if @schema_level_validations_applied

          adapter.build_schema_validations(self, @schema_definition.schema)
          @schema_level_validations_applied = true
        end
      end
    end
  end
end
