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
    def initialize(klass, property_name, type, constraints)
      @klass = klass
      @property_name = property_name.to_sym
      @type = type
      @constraints = constraints || {}
    end

    # Apply validations based on property type and constraints
    def apply_validations
      # Skip if the property is optional/nullable and nilable_is_optional is true
      apply_presence_validation unless optional?
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
    def nilable_type?
      @type.respond_to?(:nilable?) && @type.nilable?
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
      elsif [TrueClass, FalseClass].include?(type_class)
        apply_boolean_validations
      elsif type_class == Hash
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
        TrueClass # Use TrueClass as a proxy for T::Boolean
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
      length_options = {}
      length_options[:minimum] = @constraints[:min_length] if @constraints[:min_length]
      length_options[:maximum] = @constraints[:max_length] if @constraints[:max_length]
      @klass.validates @property_name, length: length_options if length_options.any?
    end

    # Apply format-specific validations (email, url, etc.)
    def apply_format_validation(format)
      case format.to_s
      when 'email'
        @klass.validates @property_name, format: {
          with: URI::MailTo::EMAIL_REGEXP,
          message: 'must be a valid email address'
        }
      when 'uri', 'url'
        @klass.validates @property_name, format: {
          with: URI::DEFAULT_PARSER.make_regexp,
          message: 'must be a valid URL'
        }
      when 'uuid'
        uuid_regex = /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i
        @klass.validates @property_name, format: {
          with: uuid_regex,
          message: 'must be a valid UUID'
        }
      when 'date'
        @klass.validates @property_name, format: {
          with: /\A\d{4}-\d{2}-\d{2}\z/,
          message: 'must be a valid date in YYYY-MM-DD format'
        }
      when 'date-time'
        # ISO 8601 date-time format
        @klass.validates @property_name, format: {
          with: /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})?\z/,
          message: 'must be a valid ISO 8601 date-time'
        }
      when 'time'
        @klass.validates @property_name, format: {
          with: /\A\d{2}:\d{2}:\d{2}(?:\.\d+)?\z/,
          message: 'must be a valid time in HH:MM:SS format'
        }
      end
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
      options = { only_integer: only_integer }

      # Add range constraints
      options[:greater_than_or_equal_to] = @constraints[:minimum] if @constraints[:minimum]
      options[:less_than_or_equal_to] = @constraints[:maximum] if @constraints[:maximum]
      options[:greater_than] = @constraints[:exclusive_minimum] if @constraints[:exclusive_minimum]
      options[:less_than] = @constraints[:exclusive_maximum] if @constraints[:exclusive_maximum]

      @klass.validates @property_name, numericality: options

      # Add multiple_of validation
      return unless @constraints[:multiple_of]

      @klass.validate do |record|
        value = record.public_send(@property_name)
        if value && (value % @constraints[:multiple_of] != 0)
          record.errors.add(@property_name, "must be a multiple of #{@constraints[:multiple_of]}")
        end
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
        @klass.validate do |record|
          value = record.public_send(@property_name)
          record.errors.add(@property_name, 'must contain unique items') if value && value.uniq.length != value.length
        end
      end

      # Validate array item types if using T::Array[SomeType]
      return unless type.respond_to?(:type_parameter)

      inner_type = type.type_parameter
      @klass.validate do |record|
        value = record.public_send(@property_name)
        if value.is_a?(Array)
          value.each_with_index do |item, index|
            unless item.is_a?(inner_type)
              record.errors.add(@property_name, "item at index #{index} must be a #{inner_type}")
            end
          end
        end
      end
    end

    # Validate boolean-specific constraints
    def apply_boolean_validations
      # For boolean values, validate inclusion in [true, false]
      @klass.validates @property_name, inclusion: { in: [true, false] }, allow_nil: optional?
    end

    # Validate object/hash-specific constraints
    def apply_object_validations
      # Currently just validates it's a hash
      # Nested validation would require recursion
      @klass.validate do |record|
        value = record.public_send(@property_name)
        record.errors.add(@property_name, 'must be a hash') if value && !value.is_a?(Hash)
      end
    end

    # Apply enum validation for inclusion in a specific list
    def apply_enum_validation
      @klass.validates @property_name, inclusion: {
        in: @constraints[:enum],
        message: "must be one of: #{@constraints[:enum].join(', ')}"
      }
    end

    # Apply const validation for equality with a specific value
    def apply_const_validation
      const_value = @constraints[:const]
      @klass.validate do |record|
        value = record.public_send(@property_name)
        record.errors.add(@property_name, "must be equal to #{const_value}") if !value.nil? && value != const_value
      end
    end
  end
end
