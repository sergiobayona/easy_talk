# frozen_string_literal: true
# typed: true

module EasyTalk
  # Helper module for generating consistent error messages
  module ErrorHelper
    extend T::Sig

    BOOLEAN_VALUES = [true, false].freeze

    def self.raise_constraint_error(property_name:, constraint_name:, expected:, got:)
      message = "Error in property '#{property_name}': Constraint '#{constraint_name}' expects #{expected}, " \
                "but received #{got.inspect} (#{got.class})."
      raise ConstraintError, message
    end

    def self.raise_array_constraint_error(property_name:, constraint_name:, index:, expected:, got:)
      message = "Error in property '#{property_name}': Constraint '#{constraint_name}' at index #{index} " \
                "expects #{expected}, but received #{got.inspect} (#{got.class})."
      raise ConstraintError, message
    end

    def self.raise_unknown_option_error(property_name:, option:, valid_options:)
      option = option.keys.first if option.is_a?(Hash)
      message = "Unknown option '#{option}' for property '#{property_name}'. " \
                "Valid options are: #{valid_options.join(', ')}."
      raise UnknownOptionError, message
    end

    def self.extract_inner_type(type_info)
      # No change needed here
      if type_info.respond_to?(:type) && type_info.type.respond_to?(:raw_type)
        type_info.type.raw_type
      # special boolean handling
      elsif TypeIntrospection.boolean_type?(type_info.try(:type))
        T::Boolean
      elsif type_info.respond_to?(:type_parameter)
        type_info.type_parameter
      elsif type_info.respond_to?(:raw_a) && type_info.respond_to?(:raw_b)
        # Handle SimplePairUnion types
        [type_info.raw_a, type_info.raw_b]
      elsif type_info.respond_to?(:types)
        # Handle complex union types
        type_info.types.map { |t| t.respond_to?(:raw_type) ? t.raw_type : t }
      else
        # Fallback to something sensible
        Object
      end
    end

    def self.validate_typed_array_values(property_name:, constraint_name:, type_info:, array_value:)
      # Raise error if value is not an array but type expects one
      unless array_value.is_a?(Array)
        inner_type = extract_inner_type(type_info)
        expected_desc = TypeIntrospection.boolean_type?(inner_type) ? 'Boolean (true or false)' : inner_type.to_s
        raise_constraint_error(
          property_name: property_name,
          constraint_name: constraint_name,
          expected: expected_desc,
          got: array_value
        )
      end

      inner_type = extract_inner_type(type_info)
      array_value.each_with_index do |element, index|
        validate_array_element(
          property_name: property_name,
          constraint_name: constraint_name,
          inner_type: inner_type,
          element: element,
          index: index
        )
      end
    end

    def self.validate_array_element(property_name:, constraint_name:, inner_type:, element:, index:)
      if inner_type.is_a?(Array)
        validate_union_element(property_name, constraint_name, inner_type, element, index)
      else
        validate_single_type_element(property_name, constraint_name, inner_type, element, index)
      end
    end

    def self.validate_union_element(property_name, constraint_name, inner_type, element, index)
      return if inner_type.any? { |t| element.is_a?(t) }

      raise_array_constraint_error(
        property_name: property_name,
        constraint_name: constraint_name,
        index: index,
        expected: inner_type.join(' or '),
        got: element
      )
    end

    def self.validate_single_type_element(property_name, constraint_name, inner_type, element, index)
      # Skip if element is a boolean (booleans are valid in many contexts)
      return if BOOLEAN_VALUES.include?(element)

      if TypeIntrospection.boolean_type?(inner_type)
        raise_array_constraint_error(
          property_name: property_name,
          constraint_name: constraint_name,
          index: index,
          expected: 'Boolean (true or false)',
          got: element
        )
      elsif !element.is_a?(inner_type)
        raise_array_constraint_error(
          property_name: property_name,
          constraint_name: constraint_name,
          index: index,
          expected: inner_type,
          got: element
        )
      end
    end

    def self.validate_constraint_value(property_name:, constraint_name:, value_type:, value:)
      return if value.nil?

      if TypeIntrospection.boolean_type?(value_type)
        return if value.is_a?(Array) && value.all? { |v| BOOLEAN_VALUES.include?(v) }

        unless BOOLEAN_VALUES.include?(value)
          raise_constraint_error(
            property_name: property_name,
            constraint_name: constraint_name,
            expected: 'Boolean (true or false)',
            got: value
          )
        end
        return
      end

      # Handle simple scalar types (String, Integer, etc.)
      if value_type.is_a?(Class)
        unless value.is_a?(value_type)
          raise_constraint_error(
            property_name: property_name,
            constraint_name: constraint_name,
            expected: value_type,
            got: value
          )
        end
      # Handle array types specifically
      elsif TypeIntrospection.typed_array?(value_type)
        # This is an array type, validate it
        validate_typed_array_values(
          property_name: property_name,
          constraint_name: constraint_name,
          type_info: value_type,
          array_value: value
        )
      # Handle Sorbet type objects
      elsif value_type.class.ancestors.include?(T::Types::Base)
        # Extract the inner type
        inner_type = extract_inner_type(value_type)

        if inner_type.is_a?(Array)
          # For union types, check if the value matches any of the allowed types
          unless inner_type.any? { |t| value.is_a?(t) }
            expected = inner_type.join(' or ')
            raise_constraint_error(
              property_name: property_name,
              constraint_name: constraint_name,
              expected: expected,
              got: value
            )
          end
        elsif !value.is_a?(inner_type)
          raise_constraint_error(
            property_name: property_name,
            constraint_name: constraint_name,
            expected: inner_type,
            got: value
          )
        end
      end
    end
  end
end
