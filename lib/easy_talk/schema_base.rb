# frozen_string_literal: true
# typed: true

require_relative 'builders/object_builder'
require_relative 'schema_definition'

module EasyTalk
  # Shared foundation for both EasyTalk::Schema and EasyTalk::Model.
  #
  # This module extracts the common instance and class methods so that
  # Schema (lightweight, no validations) and Model (full ActiveModel
  # validations) stay in sync without code duplication.
  module SchemaBase
    # Instance methods shared by Schema and Model.
    #
    # Each including module provides its own `initialize` that:
    #   1. Sets `@additional_properties = {}`
    #   2. Performs attribute assignment (manually or via ActiveModel)
    #   3. Calls `initialize_schema_properties(provided_keys)`
    module InstanceMethods
      private

      def initialize_schema_properties(provided_keys)
        schema_def = self.class.schema_definition
        return unless schema_def.respond_to?(:schema) && schema_def.schema.is_a?(Hash)

        (schema_def.schema[:properties] || {}).each do |prop_name, prop_definition|
          process_property_initialization(prop_name, prop_definition, provided_keys)
        end
      end

      def process_property_initialization(prop_name, prop_definition, provided_keys)
        defined_type = prop_definition[:type]
        nilable_type = defined_type.respond_to?(:nilable?) && defined_type.nilable?

        apply_default_value(prop_name, prop_definition, provided_keys)

        current_value = public_send(prop_name)
        return if nilable_type && current_value.nil?

        defined_type = T::Utils::Nilable.get_underlying_type(defined_type) if nilable_type
        instantiate_nested_models(prop_name, defined_type, current_value)
      end

      def apply_default_value(prop_name, prop_definition, provided_keys)
        return if provided_keys.include?(prop_name)

        default_value = prop_definition.dig(:constraints, :default)
        public_send("#{prop_name}=", EasyTalk.deep_dup(default_value)) unless default_value.nil?
      end

      def instantiate_nested_models(prop_name, defined_type, current_value)
        if easy_talk_class?(defined_type) && current_value.is_a?(Hash)
          public_send("#{prop_name}=", defined_type.new(current_value))
          return
        end

        instantiate_array_items(prop_name, defined_type, current_value)
      end

      def easy_talk_class?(type)
        type.is_a?(Class) && (
          type.include?(EasyTalk::Model) || type.include?(EasyTalk::Schema)
        )
      end

      def instantiate_array_items(prop_name, defined_type, current_value)
        return unless defined_type.is_a?(T::Types::TypedArray) && current_value.is_a?(Array)

        item_type = defined_type.type.respond_to?(:raw_type) ? defined_type.type.raw_type : nil
        return unless easy_talk_class?(item_type)

        instantiated = current_value.map { |item| item.is_a?(Hash) ? item_type.new(item) : item }
        public_send("#{prop_name}=", instantiated)
      end

      public

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

      def to_hash
        properties_to_include = (self.class.schema_definition.schema[:properties] || {}).keys
        return {} if properties_to_include.empty?

        properties_to_include.to_h { |prop| [prop.to_s, send(prop)] }
      end

      def as_json(_options = {})
        to_hash.merge(@additional_properties)
      end

      def to_h
        to_hash.merge(@additional_properties)
      end

      def ==(other)
        case other
        when Hash
          self_hash = (self.class.schema_definition.schema[:properties] || {}).keys.to_h { |prop| [prop, send(prop)] }
          other_normalized = other.transform_keys(&:to_sym)
          self_hash == other_normalized
        else
          super
        end
      end
    end

    # Class methods shared by Schema and Model.
    module ClassMethods
      include SchemaMethods

      def schema
        @schema ||= if defined?(@schema_definition) && @schema_definition
                      build_schema(@schema_definition)
                    else
                      {}
                    end
      end

      def define_schema(&)
        raise ArgumentError, 'The class must have a name' unless name.present?

        clear_schema_state!

        @schema_definition = SchemaDefinition.new(name)
        @schema_definition.klass = self
        @schema_definition.instance_eval(&)

        defined_properties = (@schema_definition.schema[:properties] || {}).keys
        attr_accessor(*defined_properties)

        @schema_definition
      end

      def schema_definition
        @schema_definition ||= {}
      end

      def additional_properties_allowed?
        ap = @schema_definition&.schema&.fetch(:additional_properties, false)
        ap == true || ap.is_a?(Class) || ap.is_a?(Hash)
      end

      def properties
        (@schema_definition&.schema&.dig(:properties) || {}).keys
      end

      private

      def clear_schema_state!
        @schema = nil
        @json_schema = nil
      end

      def build_schema(schema_definition)
        Builders::ObjectBuilder.new(schema_definition).build
      end
    end
  end
end
