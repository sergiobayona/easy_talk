module EsquemaBase
  class PropertyValidation
    extend T::Sig

    # These are constraints supported for each property type.
    NUMERIC_TYPE_CONSTRAINTS = %i[minimum maximum exclusiveMinimum exclusiveMaximum multipleOf].freeze
    STRING_TYPE_CONSTRAINTS = %i[maxLength minLength pattern format].freeze
    ARRAY_TYPE_CONSTRAINTS = %i[maxItems minItems uniqueItems items].freeze
    OBJECT_TYPE_CONSTRAINTS = %i[required maxProperties minProperties properties patternProperties additionalProperties
                                 dependencies propertyNames].freeze

    SUPPORTED_TYPES = {
      'String' => STRING_TYPE_CONSTRAINTS,
      'Integer' => NUMERIC_TYPE_CONSTRAINTS,
      'Numeric' => NUMERIC_TYPE_CONSTRAINTS,
      'Float' => NUMERIC_TYPE_CONSTRAINTS,
      'T::Boolean' => [],
      'Array' => ARRAY_TYPE_CONSTRAINTS,
      'Hash' => OBJECT_TYPE_CONSTRAINTS,
      'NilClass' => [],
      'Date' => STRING_TYPE_CONSTRAINTS,
      'DateTime' => STRING_TYPE_CONSTRAINTS,
      'Time' => STRING_TYPE_CONSTRAINTS,
      'Object' => OBJECT_TYPE_CONSTRAINTS
    }.freeze

    # These are constraints supported for all types.
    GENERIC_KEYWORDS = %i[type default title description enum const].freeze

    attr_reader :name, :options

    class << self
      def validate!(property_name, type, constraints)
        type = Array.wrap(type)
        validate_type!(property_name, type)
        return if constraints.nil?

        validate_constraints!(property_name, type, constraints)
      end

      def validate_type!(property_name, types)
        raise EsquemaBase::UnsupportedTypeError, "Property: '#{property_name}' must have a valid type." if types.empty?

        types.each do |type|
          next if type.respond_to?(:name) && SUPPORTED_TYPES.key?(type.name)

          next if type.respond_to?(:underlying_class) && SUPPORTED_TYPES.key?(type.underlying_class.name)

          raise EsquemaBase::UnsupportedTypeError,
                "Unsupported type: '#{type}' for property: '#{property_name}'."
        end
      end

      def validate_constraints!(property_name, types, constraints)
        constraints.each_key do |constraint|
          applicable_types = types.select { |_type| type_constraint_applicable?(types, constraint) }
          if applicable_types.empty?
            raise EsquemaBase::UnsupportedConstraintError,
                  "Constraint '#{constraint}' is not applicable to type: #{types.join(', ')} for '#{property_name}'"
          end
        end
      end

      def type_constraint_applicable?(types, constraint)
        return true if GENERIC_KEYWORDS.include?(constraint)

        types.any? do |type|
          SUPPORTED_TYPES[type.name]&.include?(constraint)
        end
      end
    end
  end
end
