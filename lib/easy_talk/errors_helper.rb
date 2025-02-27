module EasyTalk
  module ErrorHelper
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
      elsif type_info.try(:type).try(:name) == 'T::Boolean'
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
      # Skip validation if it's not actually an array
      return unless array_value.is_a?(Array)

      # Extract the inner type from the array type definition
      inner_type = extract_inner_type(type_info)

      # Check each element of the array
      array_value.each_with_index do |element, index|
        if inner_type.is_a?(Array)
          # For union types, check if the element matches any of the allowed types
          unless inner_type.any? { |t| element.is_a?(t) }
            expected = inner_type.join(' or ')
            raise_array_constraint_error(
              property_name: property_name,
              constraint_name: constraint_name,
              index: index,
              expected: expected,
              got: element
            )
          end
        else
          # For single types, just check against that type
          next if [true, false].include?(element)

          unless element.is_a?(inner_type)
            raise_array_constraint_error(
              property_name: property_name,
              constraint_name: constraint_name,
              index: index,
              expected: inner_type,
              got: element
            )
          end
        end
      end
    end

    def self.validate_constraint_value(property_name:, constraint_name:, value_type:, value:)
      return if value.nil?

      if value_type.to_s.include?('Boolean')
        return if value.is_a?(Array) && value.all? { |v| [true, false].include?(v) }

        unless [true, false].include?(value)
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
      elsif value_type.class.name.include?('TypedArray') ||
            (value_type.respond_to?(:to_s) && value_type.to_s.include?('T::Array'))
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
