# frozen_string_literal: true

module EasyTalk
  module ValidationAdapters
    # Schema-level validations for object-level constraints.
    #
    # This module provides validations for JSON Schema keywords that apply
    # to the object as a whole rather than individual properties:
    # - minProperties: minimum number of properties that must be present
    # - maxProperties: maximum number of properties that can be present
    # - dependentRequired: conditional property requirements
    #
    module SchemaValidation
      # Apply all applicable schema-level validations.
      #
      # @param klass [Class] The model class to apply validations to
      # @param schema [Hash] The full schema hash containing schema-level constraints
      # @return [void]
      def self.apply(klass, schema)
        apply_min_properties_validation(klass, schema[:min_properties]) if schema[:min_properties]
        apply_max_properties_validation(klass, schema[:max_properties]) if schema[:max_properties]
        apply_dependent_required_validation(klass, schema[:dependent_required]) if schema[:dependent_required]
      end

      # Apply minimum properties validation.
      #
      # @param klass [Class] The model class
      # @param min_count [Integer] Minimum number of properties that must be present
      def self.apply_min_properties_validation(klass, min_count)
        define_count_method(klass)

        klass.validate do |record|
          present_count = record.send(:count_present_properties)
          if present_count < min_count
            record.errors.add(:base, "must have at least #{min_count} #{min_count == 1 ? 'property' : 'properties'} present")
          end
        end
      end

      # Apply maximum properties validation.
      #
      # @param klass [Class] The model class
      # @param max_count [Integer] Maximum number of properties that can be present
      def self.apply_max_properties_validation(klass, max_count)
        define_count_method(klass)

        klass.validate do |record|
          present_count = record.send(:count_present_properties)
          if present_count > max_count
            record.errors.add(:base, "must have at most #{max_count} #{max_count == 1 ? 'property' : 'properties'} present")
          end
        end
      end

      # Apply dependent required validation.
      # When a trigger property is present, all dependent properties must also be present.
      #
      # @param klass [Class] The model class
      # @param dependencies [Hash<String, Array<String>>] Map of trigger properties to required properties
      def self.apply_dependent_required_validation(klass, dependencies)
        dependencies.each do |trigger_property, required_properties|
          trigger_prop = trigger_property.to_sym
          required_props = required_properties.map(&:to_sym)

          klass.validate do |record|
            trigger_value = record.public_send(trigger_prop)
            trigger_present = trigger_value.present? || trigger_value == false

            next unless trigger_present

            required_props.each do |required_prop|
              value = record.public_send(required_prop)
              value_present = value.present? || value == false

              record.errors.add(required_prop, "is required when #{trigger_prop} is present") unless value_present
            end
          end
        end
      end

      # Define the count_present_properties private instance method on the class if not already defined.
      # The method counts how many schema properties have non-nil/non-blank values.
      #
      # @param klass [Class] The model class
      def self.define_count_method(klass)
        # Check for private methods as well with the second argument
        return if klass.method_defined?(:count_present_properties, true)

        klass.send(:define_method, :count_present_properties) do
          schema_props = self.class.schema_definition.schema[:properties] || {}
          schema_props.keys.count do |prop|
            value = public_send(prop)
            value.present? || value == false # false is a valid present value
          end
        end
        klass.send(:private, :count_present_properties)
      end

      private_class_method :define_count_method
    end
  end
end
