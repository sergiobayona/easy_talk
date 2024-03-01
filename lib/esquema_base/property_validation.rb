module EsquemaBase
  class PropertyValidation
    extend T::Sig

    SUPPORTED_TYPES = {
      String: 'string',
      Integer: 'integer',
      Numeric: 'number',
      Boolean: 'boolean',
      Array: 'array',
      Hash: 'object',
      nil: 'null',
      Date: 'date',
      DateTime: 'datetime',
      Time: 'time'
    }.freeze

    # These are constraints supported for each property type.
    NUMERIC_TYPE_CONSTRAINTS = %i[minimum maximum exclusiveMinimum exclusiveMaximum multipleOf].freeze
    STRING_TYPE_CONSTRAINTS = %i[maxLength minLength pattern format].freeze
    ARRAY_TYPE_CONSTRAINTS = %i[maxItems minItems uniqueItems items].freeze
    OBJECT_TYPE_CONSTRAINTS = %i[required maxProperties minProperties properties patternProperties additionalProperties
                                 dependencies propertyNames].freeze

    TYPE_CONSTRAINTS = {
      String => STRING_TYPE_CONSTRAINTS,
      Integer => NUMERIC_TYPE_CONSTRAINTS,
      Float => NUMERIC_TYPE_CONSTRAINTS,
      T::Types::TypedArray => ARRAY_TYPE_CONSTRAINTS,
      'object' => OBJECT_TYPE_CONSTRAINTS
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

      def validate_type!(property_name, type)
        type.each do |t|
          next if SUPPORTED_TYPES.key?(t.to_s.to_sym)

          next if t.respond_to?(:underlying_class) && SUPPORTED_TYPES.key?(t.underlying_class.to_s.to_sym)

          raise EsquemaBase::UnsupportedTypeError,
                "Unsupported type for property #{property_name}: #{t}"
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
          TYPE_CONSTRAINTS[type]&.include?(constraint)
        end
      end
    end
  end
end
