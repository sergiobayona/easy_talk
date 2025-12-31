# frozen_string_literal: true

require 'uri'

module EasyTalk
  module ValidationAdapters
    # ActiveModel validation adapter.
    #
    # This is the default adapter that converts JSON Schema constraints into
    # ActiveModel validations. It provides the same validation behavior as
    # the original EasyTalk::ValidationBuilder.
    #
    # @example Using the ActiveModel adapter (default)
    #   class User
    #     include EasyTalk::Model
    #
    #     define_schema do
    #       property :email, String, format: 'email'
    #     end
    #   end
    #
    #   user = User.new(email: 'invalid')
    #   user.valid? # => false
    #   user.errors[:email] # => ["must be a valid email address"]
    #
    class ActiveModelAdapter < Base
      # Apply validations based on property type and constraints.
      #
      # @return [void]
      def apply_validations
        # Determine if the type is boolean
        type_class = get_type_class(@type)
        is_boolean = type_class == [TrueClass, FalseClass] ||
                     type_class == TrueClass ||
                     type_class == FalseClass ||
                     TypeIntrospection.boolean_type?(@type)

        # Determine if the type is an array (empty arrays should be valid)
        is_array = type_class == Array || @type.is_a?(T::Types::TypedArray)

        # Skip presence validation for booleans, nilable types, and arrays
        # (empty arrays are valid - use min_items constraint if you need non-empty)
        apply_presence_validation unless optional? || is_boolean || nilable_type? || is_array

        # For non-nilable arrays, add nil check (but allow empty arrays)
        # Per JSON Schema: optional means the property can be omitted, but if present,
        # null is only valid when the type includes null (T.nilable)
        apply_array_presence_validation if is_array && !nilable_type?

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
                                             FalseClass].include?(type_class) || TypeIntrospection.boolean_type?(type)
          apply_boolean_validations
        elsif type_class.is_a?(Object) && type_class.include?(EasyTalk::Model)
          apply_object_validations
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
        apply_pattern_validation if @constraints[:pattern]

        # Handle length constraints
        apply_length_validations
      end

      # Apply pattern validation (only for string values per JSON Schema spec)
      def apply_pattern_validation
        prop_name = @property_name
        pattern = Regexp.new(@constraints[:pattern])
        is_optional = optional?

        @klass.validates prop_name, format: { with: pattern },
                                    allow_nil: is_optional,
                                    if: ->(record) { record.public_send(prop_name).is_a?(String) }
      end

      # Apply length validations for strings
      def apply_length_validations
        length_options = {}
        length_options[:minimum] = @constraints[:min_length] if valid_length_constraint?(:min_length)
        length_options[:maximum] = @constraints[:max_length] if valid_length_constraint?(:max_length)
        return unless length_options.any?

        length_options[:allow_nil] = optional? || nilable_type?
        @klass.validates @property_name, length: length_options
      rescue ArgumentError
        # Silently ignore invalid length constraints
      end

      # Check if a length constraint is valid
      def valid_length_constraint?(key)
        @constraints[key].is_a?(Numeric) && @constraints[key] >= 0
      end

      # Apply format-specific validations (email, url, etc.)
      # Per JSON Schema spec, format validation only applies to string values
      def apply_format_validation(format)
        format_configs = {
          'email' => { with: URI::MailTo::EMAIL_REGEXP, message: 'must be a valid email address' },
          'uri' => { with: URI::DEFAULT_PARSER.make_regexp, message: 'must be a valid URL' },
          'url' => { with: URI::DEFAULT_PARSER.make_regexp, message: 'must be a valid URL' },
          'uuid' => { with: /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i,
                      message: 'must be a valid UUID' },
          'date' => { with: /\A\d{4}-\d{2}-\d{2}\z/, message: 'must be a valid date in YYYY-MM-DD format' },
          'date-time' => { with: /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})?\z/,
                           message: 'must be a valid ISO 8601 date-time' },
          'time' => { with: /\A\d{2}:\d{2}:\d{2}(?:\.\d+)?\z/, message: 'must be a valid time in HH:MM:SS format' }
        }

        config = format_configs[format.to_s]
        return unless config

        prop_name = @property_name
        config[:allow_nil] = optional? || nilable_type?
        # Per JSON Schema spec, format validation only applies when value is a string
        @klass.validates prop_name, format: config, if: ->(record) { record.public_send(prop_name).is_a?(String) }
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

        # Add range constraints - only if they are numeric
        options[:greater_than_or_equal_to] = @constraints[:minimum] if @constraints[:minimum].is_a?(Numeric)
        options[:less_than_or_equal_to] = @constraints[:maximum] if @constraints[:maximum].is_a?(Numeric)
        options[:greater_than] = @constraints[:exclusive_minimum] if @constraints[:exclusive_minimum].is_a?(Numeric)
        options[:less_than] = @constraints[:exclusive_maximum] if @constraints[:exclusive_maximum].is_a?(Numeric)

        @klass.validates @property_name, numericality: options

        # Add multiple_of validation
        apply_multiple_of_validation if @constraints[:multiple_of]
      rescue ArgumentError
        # Silently ignore invalid numeric constraints
      end

      # Apply multiple_of validation for numeric types
      def apply_multiple_of_validation
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
        apply_unique_items_validation if @constraints[:unique_items]

        # Validate array item types if using T::Array[SomeType]
        apply_array_item_type_validation(type) if type.is_a?(T::Types::TypedArray)
      end

      # Apply unique items validation for arrays
      def apply_unique_items_validation
        prop_name = @property_name
        @klass.validate do |record|
          value = record.public_send(prop_name)
          record.errors.add(prop_name, 'must contain unique items') if value && value.uniq.length != value.length
        end
      end

      # Apply array item type and nested model validation
      def apply_array_item_type_validation(type)
        # Get inner type from T::Types::TypedArray (uses .type, which returns T::Types::Simple)
        inner_type_wrapper = type.type
        inner_type = inner_type_wrapper.respond_to?(:raw_type) ? inner_type_wrapper.raw_type : inner_type_wrapper
        prop_name = @property_name
        is_easy_talk_model = inner_type.is_a?(Class) && inner_type.include?(EasyTalk::Model)

        @klass.validate do |record|
          value = record.public_send(prop_name)
          next unless value.is_a?(Array)

          value.each_with_index do |item, index|
            unless item.is_a?(inner_type)
              record.errors.add(prop_name, "item at index #{index} must be a #{inner_type}")
              next
            end

            # Recursively validate nested EasyTalk::Model items
            next unless is_easy_talk_model && !item.valid?

            item.errors.each do |error|
              nested_key = "#{prop_name}[#{index}].#{error.attribute}"
              record.errors.add(nested_key.to_sym, error.message)
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
          apply_boolean_presence_validation
        end

        # Add type validation to ensure the value is actually a boolean
        apply_boolean_type_validation
      end

      # Apply presence validation for boolean (nil check with custom message)
      def apply_boolean_presence_validation
        prop_name = @property_name
        @klass.validate do |record|
          value = record.public_send(prop_name)
          record.errors.add(prop_name, :blank) if value.nil?
        end
      end

      # Apply presence validation for arrays (nil check, but allow empty arrays)
      def apply_array_presence_validation
        prop_name = @property_name
        @klass.validate do |record|
          value = record.public_send(prop_name)
          record.errors.add(prop_name, :blank) if value.nil?
        end
      end

      # Apply type validation for boolean
      def apply_boolean_type_validation
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
          next unless nested_object

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
            elsif !nested_object.valid?
              # If it's the correct type and not empty, validate it
              # Merge errors from the nested object into the parent
              nested_object.errors.each do |error|
                # Prefix the attribute name (e.g., 'email.address')
                nested_key = "#{prop_name}.#{error.attribute}"
                record.errors.add(nested_key.to_sym, error.message)
              end
            end
          else
            # If present but not the correct type, add a type error
            record.errors.add(prop_name, "must be a valid #{expected_type.name}")
          end
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
end
