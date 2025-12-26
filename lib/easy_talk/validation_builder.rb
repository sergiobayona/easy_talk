# frozen_string_literal: true

require 'uri'

module EasyTalk
  # The ValidationBuilder creates ActiveModel validations based on JSON Schema constraints
  class ValidationBuilder
    # Build validations for a property and apply them to the model class
    #
    # @param klass [Class] The model class to apply validations to
    # @param property_name [Symbol, String] The name of the property
    # @param type [Class, Object] The type of the property
    # @param constraints [Hash] The JSON Schema constraints for the property
    # @return [void]
    def self.build_validations(klass, property_name, type, constraints)
      builder = new(klass, property_name, type, constraints)
      builder.apply_validations
    end

    # Initialize a new ValidationBuilder
    #
    # @param klass [Class] The model class to apply validations to
    # @param property_name [Symbol, String] The name of the property
    # @param type [Class, Object] The type of the property
    # @param constraints [Hash] The JSON Schema constraints for the property
    attr_reader :klass, :property_name, :type, :constraints

    def initialize(klass, property_name, type, constraints)
      @klass = klass
      @property_name = property_name.to_sym
      @type = type
      @constraints = constraints || {}
    end

    # Apply validations based on property type and constraints
    def apply_validations
      # Determine if the type is boolean
      type_class = get_type_class(@type)
      is_boolean = type_class == [TrueClass, FalseClass] ||
                   type_class == TrueClass ||
                   type_class == FalseClass ||
                   @type.to_s.include?('T::Boolean')

      # Skip presence validation for booleans and nilable types
      apply_presence_validation unless optional? || is_boolean || nilable_type?
      if nilable_type?
        # For nilable types, get the inner type and apply validations to it
        inner_type = extract_inner_type(@type)
        apply_type_validations(inner_type)
      else
        apply_type_validations(@type)
      end

      # Common validations for most types
      apply_enum_validation if @constraints[:enum]
      apply_const_validation if @constraints[:const]
    end

    private

    # Determine if a property is optional based on constraints and configuration
    def optional?
      @constraints[:optional] == true ||
        (@type.respond_to?(:nilable?) && @type.nilable? && EasyTalk.configuration.nilable_is_optional)
    end

    # Check if the type is nilable (e.g., T.nilable(String))
    def nilable_type?(type = @type)
      type.respond_to?(:nilable?) && type.nilable?
    end

    # Extract the inner type from a complex type like T.nilable(String)
    def extract_inner_type(type)
      if type.respond_to?(:unwrap_nilable) && type.unwrap_nilable.respond_to?(:raw_type)
        type.unwrap_nilable.raw_type
      elsif type.respond_to?(:types)
        # For union types like T.nilable(String), extract the non-nil type
        type.types.find { |t| t.respond_to?(:raw_type) && t.raw_type != NilClass }
      else
        type
      end
    end

    # Apply validations based on the type of the property
    def apply_type_validations(type)
      type_class = get_type_class(type)

      if type_class == String
        apply_string_validations
      elsif type_class == Integer
        apply_integer_validations
      elsif [Float, BigDecimal].include?(type_class)
        apply_number_validations
      elsif type_class == Array
        apply_array_validations(type)
      elsif type_class == [TrueClass,
                           FalseClass] || [TrueClass,
                                           FalseClass].include?(type_class) || type.to_s.include?('T::Boolean')
        apply_boolean_validations
      elsif type_class.is_a?(Object) && type_class.include?(EasyTalk::Model)
        apply_object_validations
      end
    end

    # Determine the actual class for a type, handling Sorbet types
    def get_type_class(type)
      if type.is_a?(Class)
        type
      elsif type.respond_to?(:raw_type)
        type.raw_type
      elsif type.is_a?(T::Types::TypedArray)
        Array
      elsif type.is_a?(Symbol) || type.is_a?(String)
        begin
          type.to_s.classify.constantize
        rescue StandardError
          String
        end
      elsif type.to_s.include?('T::Boolean')
        [TrueClass, FalseClass] # Return both boolean classes
      elsif nilable_type?(type)
        extract_inner_type(type)
      else
        String # Default fallback
      end
    end

    # Add presence validation for the property
    def apply_presence_validation
      @klass.validates @property_name, presence: true
    end

    # Validate string-specific constraints
    def apply_string_validations
      # Handle format constraints
      apply_format_validation(@constraints[:format]) if @constraints[:format]

      # Handle pattern (regex) constraints
      @klass.validates @property_name, format: { with: Regexp.new(@constraints[:pattern]) } if @constraints[:pattern]

      # Handle length constraints
      begin
        length_options = {}
        length_options[:minimum] = @constraints[:min_length] if @constraints[:min_length].is_a?(Numeric) && @constraints[:min_length] >= 0
        length_options[:maximum] = @constraints[:max_length] if @constraints[:max_length].is_a?(Numeric) && @constraints[:max_length] >= 0
        @klass.validates @property_name, length: length_options if length_options.any?
      rescue ArgumentError
        # Silently ignore invalid length constraints
      end
    end

    # Apply format-specific validations (email, url, etc.)
    def apply_format_validation(format)
      format_configs = {
        'email' => { with: URI::MailTo::EMAIL_REGEXP, message: 'must be a valid email address' },
        'uri' => { with: URI::DEFAULT_PARSER.make_regexp, message: 'must be a valid URL' },
        'url' => { with: URI::DEFAULT_PARSER.make_regexp, message: 'must be a valid URL' },
        'uuid' => { with: /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i, message: 'must be a valid UUID' },
        'date' => { with: /\A\d{4}-\d{2}-\d{2}\z/, message: 'must be a valid date in YYYY-MM-DD format' },
        'date-time' => { with: /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})?\z/, message: 'must be a valid ISO 8601 date-time' },
        'time' => { with: /\A\d{2}:\d{2}:\d{2}(?:\.\d+)?\z/, message: 'must be a valid time in HH:MM:SS format' }
      }

      config = format_configs[format.to_s]
      @klass.validates @property_name, format: config if config
    end

    # Validate integer-specific constraints
    def apply_integer_validations
      apply_numeric_validations(only_integer: true)
    end

    # Validate number-specific constraints
    def apply_number_validations
      apply_numeric_validations(only_integer: false)
    end

    # Apply numeric validations for integers and floats
    def apply_numeric_validations(only_integer: false)
      begin
        options = { only_integer: only_integer }

        # Add range constraints - only if they are numeric
        options[:greater_than_or_equal_to] = @constraints[:minimum] if @constraints[:minimum].is_a?(Numeric)
        options[:less_than_or_equal_to] = @constraints[:maximum] if @constraints[:maximum].is_a?(Numeric)
        options[:greater_than] = @constraints[:exclusive_minimum] if @constraints[:exclusive_minimum].is_a?(Numeric)
        options[:less_than] = @constraints[:exclusive_maximum] if @constraints[:exclusive_maximum].is_a?(Numeric)

        @klass.validates @property_name, numericality: options
      rescue ArgumentError
        # Silently ignore invalid numeric constraints
      end

      # Add multiple_of validation
      return unless @constraints[:multiple_of]

      prop_name = @property_name
      multiple_of_value = @constraints[:multiple_of]
      @klass.validate do |record|
        value = record.public_send(prop_name)
        record.errors.add(prop_name, "must be a multiple of #{multiple_of_value}") if value && (value % multiple_of_value != 0)
      end
    end

    # Validate array-specific constraints
    def apply_array_validations(type)
      # Validate array length
      if @constraints[:min_items] || @constraints[:max_items]
        length_options = {}
        length_options[:minimum] = @constraints[:min_items] if @constraints[:min_items]
        length_options[:maximum] = @constraints[:max_items] if @constraints[:max_items]

        @klass.validates @property_name, length: length_options
      end

      # Validate uniqueness within the array
      if @constraints[:unique_items]
        prop_name = @property_name
        @klass.validate do |record|
          value = record.public_send(prop_name)
          record.errors.add(prop_name, 'must contain unique items') if value && value.uniq.length != value.length
        end
      end

      # Validate array item types if using T::Array[SomeType]
      return unless type.respond_to?(:type_parameter)

      inner_type = type.type_parameter
      prop_name = @property_name
      @klass.validate do |record|
        value = record.public_send(prop_name)
        if value.is_a?(Array)
          value.each_with_index do |item, index|
            record.errors.add(prop_name, "item at index #{index} must be a #{inner_type}") unless item.is_a?(inner_type)
          end
        end
      end
    end

    # Validate boolean-specific constraints
    def apply_boolean_validations
      # For boolean values, validate inclusion in [true, false]
      # If not optional, don't allow nil (equivalent to presence validation for booleans)
      if optional?
        @klass.validates @property_name, inclusion: { in: [true, false] }, allow_nil: true
      else
        @klass.validates @property_name, inclusion: { in: [true, false] }
        # Add custom validation for nil values that provides the "can't be blank" message
        prop_name = @property_name
        @klass.validate do |record|
          value = record.public_send(prop_name)
          record.errors.add(prop_name, "can't be blank") if value.nil?
        end
      end

      # Add type validation to ensure the value is actually a boolean
      prop_name = @property_name
      @klass.validate do |record|
        value = record.public_send(prop_name)
        record.errors.add(prop_name, 'must be a boolean') if value && ![true, false].include?(value)
      end
    end

    # Validate object/hash-specific constraints
    def apply_object_validations
      # Capture necessary variables outside the validation block's scope
      prop_name = @property_name
      expected_type = get_type_class(@type) # Get the raw model class

      @klass.validate do |record|
        nested_object = record.public_send(prop_name)

        # Only validate if the nested object is present
        if nested_object
          # Check if the object is of the expected type (e.g., an actual Email instance)
          if nested_object.is_a?(expected_type)
            # Check if this object appears to be empty (created from an empty hash)
            # by checking if all defined properties are nil/blank
            properties = expected_type.schema_definition.schema[:properties] || {}
            all_properties_blank = properties.keys.all? do |property|
              value = nested_object.public_send(property)
              value.nil? || (value.respond_to?(:empty?) && value.empty?)
            end

            if all_properties_blank
              # Treat as blank and add a presence error to the parent field
              record.errors.add(prop_name, "can't be blank")
            else
              # If it's the correct type and not empty, validate it
              unless nested_object.valid?
                # Merge errors from the nested object into the parent
                nested_object.errors.each do |error|
                  # Prefix the attribute name (e.g., 'email.address')
                  nested_key = "#{prop_name}.#{error.attribute}"
                  record.errors.add(nested_key.to_sym, error.message)
                end
              end
            end
          else
            # If present but not the correct type, add a type error
            record.errors.add(prop_name, "must be a valid #{expected_type.name}")
          end
        end
        # NOTE: Presence validation (if nested_object is nil) is handled
        # by apply_presence_validation based on the property definition.
      end
    end

    # Apply enum validation for inclusion in a specific list
    def apply_enum_validation
      @klass.validates @property_name, inclusion: {
        in: @constraints[:enum],
        message: "must be one of: #{@constraints[:enum].join(', ')}",
        allow_nil: optional?
      }
    end

    # Apply const validation for equality with a specific value
    def apply_const_validation
      const_value = @constraints[:const]
      prop_name = @property_name
      @klass.validate do |record|
        value = record.public_send(prop_name)
        record.errors.add(prop_name, "must be equal to #{const_value}") if !value.nil? && value != const_value
      end
    end
  end
end
