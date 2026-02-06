# frozen_string_literal: true

require 'uri'
require 'time'
require_relative 'active_model_schema_validation'
require 'easy_talk/json_schema_equality'

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
      # Helper class methods for tuple validation (defined at class level for use in validate blocks)
      # Resolve a Sorbet type to a Ruby class for type checking
      def self.resolve_tuple_type_class(type)
        # Handle T.untyped - any value is valid
        return :untyped if type.is_a?(T::Types::Untyped) || type == T.untyped

        # Handle union types (T.any, T.nilable)
        return type.types.flat_map { |t| resolve_tuple_type_class(t) } if type.is_a?(T::Types::Union)

        if type.respond_to?(:raw_type)
          type.raw_type
        elsif type == T::Boolean
          [TrueClass, FalseClass]
        elsif type.is_a?(Class)
          type
        else
          type
        end
      end

      # Check if a value matches a type class (supports arrays for union types like Boolean)
      def self.type_matches?(value, type_class)
        # :untyped means any value is valid (from empty schema {} in JSON Schema)
        return true if type_class == :untyped

        if type_class.is_a?(Array)
          type_class.any? { |tc| value.is_a?(tc) }
        else
          value.is_a?(type_class)
        end
      end

      # Generate a human-readable type name for error messages
      def self.type_name_for_error(type_class)
        return 'unknown' if type_class.nil?

        if type_class.is_a?(Array)
          type_class.map { |tc| tc.respond_to?(:name) ? tc.name : tc.to_s }.join(' or ')
        elsif type_class.respond_to?(:name) && type_class.name
          type_class.name
        else
          type_class.to_s
        end
      end

      # Regex-based format validators
      REGEX_FORMAT_CONFIGS = {
        'email' => { with: /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/, message: 'must be a valid email address' },
        'uuid' => { with: /\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i,
                    message: 'must be a valid UUID' }
      }.freeze

      # Formats that require parsing validation (not just regex)
      PARSING_FORMATS = %w[date date-time time uri url].freeze

      # Build schema-level validations for object-level constraints.
      # Delegates to ActiveModelSchemaValidation module.
      #
      # @param klass [Class] The model class to apply validations to
      # @param schema [Hash] The full schema hash containing schema-level constraints
      # @return [void]
      def self.build_schema_validations(klass, schema)
        ActiveModelSchemaValidation.apply(klass, schema)
      end

      # Apply validations based on property type and constraints.
      #
      # @return [void]
      def apply_validations
        context = build_validation_context

        apply_presence_validation unless context.skip_presence_validation?
        apply_array_presence_validation if context.array_requires_presence_validation?

        apply_type_validations(context)

        apply_enum_validation if @constraints[:enum]
        apply_const_validation if @constraints[:const]
      end

      # Build ValidationContext with pre-computed values from the adapter
      def build_validation_context
        is_optional = optional?
        is_nilable = nilable_type?(@type)
        validation_type = is_nilable ? extract_inner_type(@type) : @type
        validation_type ||= @type
        type_class = get_type_class(validation_type)

        ValidationContext.new(
          klass: @klass,
          property_name: @property_name.to_sym,
          constraints: @constraints || {},
          validation_type: validation_type,
          type_class: type_class,
          optional: is_optional,
          nilable: is_nilable
        )
      end
      private :build_validation_context

      private

      # Apply validations based on the type of the property
      def apply_type_validations(context)
        if context.tuple_type?
          apply_tuple_type_validations(context.validation_type)
          return
        end

        type_class = context.type_class

        if type_class == String
          apply_string_validations
        elsif type_class == Integer
          apply_integer_validations
        elsif [Float, BigDecimal].include?(type_class)
          apply_number_validations
        elsif type_class == Array
          apply_array_validations(context.validation_type)
        elsif context.boolean?
          apply_boolean_validations
        elsif context.model_class
          apply_object_validations(context.model_class)
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
        property_name = @property_name

        @klass.validates property_name,
                         format: { with: Regexp.new(@constraints[:pattern]) },
                         if: -> { public_send(property_name).is_a?(String) }
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
        format_str = format.to_s

        # Handle parsing-based formats (date, date-time, time)
        if PARSING_FORMATS.include?(format_str)
          apply_parsing_format_validation(format_str)
          return
        end

        # Handle regex-based formats
        config = REGEX_FORMAT_CONFIGS[format_str]
        return unless config

        property_name = @property_name
        # Per JSON Schema spec, format validation only applies when value is a string
        @klass.validates property_name, format: config, if: -> { public_send(property_name).is_a?(String) }
      end

      # Apply parsing-based format validations for date, date-time, and time
      def apply_parsing_format_validation(format)
        case format
        when 'date' then apply_date_format_validation
        when 'date-time' then apply_datetime_format_validation
        when 'time' then apply_time_format_validation
        when 'uri', 'url' then apply_uri_format_validation
        end
      end

      def apply_uri_format_validation
        prop_name = @property_name
        @klass.validate do |record|
          value = record.public_send(prop_name)
          next unless value.is_a?(String)

          begin
            uri = URI.parse(value)
            record.errors.add(prop_name, 'must be a valid URL') unless uri.absolute?
          rescue URI::InvalidURIError, ArgumentError
            record.errors.add(prop_name, 'must be a valid URL')
          end
        end
      end

      def apply_date_format_validation
        prop_name = @property_name
        @klass.validate do |record|
          value = record.public_send(prop_name)
          next if value.blank? || !value.is_a?(String)

          Date.iso8601(value)
        rescue Date::Error
          record.errors.add(prop_name, 'must be a valid date in YYYY-MM-DD format')
        end
      end

      def apply_datetime_format_validation
        prop_name = @property_name
        @klass.validate do |record|
          value = record.public_send(prop_name)
          next if value.blank? || !value.is_a?(String)

          DateTime.iso8601(value)
        rescue Date::Error
          record.errors.add(prop_name, 'must be a valid ISO 8601 date-time')
        end
      end

      def apply_time_format_validation
        prop_name = @property_name
        @klass.validate do |record|
          value = record.public_send(prop_name)
          next if value.blank? || !value.is_a?(String)

          time_zone = Time.respond_to?(:zone) ? Time.zone : nil
          (time_zone || Time).parse(value)
          record.errors.add(prop_name, 'must be a valid time in HH:MM:SS format') unless value.match?(/\A\d{2}:\d{2}:\d{2}/)
        rescue ArgumentError
          record.errors.add(prop_name, 'must be a valid time in HH:MM:SS format')
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
        apply_array_length_validation

        # Validate uniqueness within the array
        apply_unique_items_validation if @constraints[:unique_items]

        # Check if this is a tuple (items constraint is an array of types)
        if @constraints[:items].is_a?(::Array)
          apply_tuple_validations(@constraints[:items], @constraints[:additional_items])
        elsif type.is_a?(T::Types::TypedArray)
          # Validate array item types if using T::Array[SomeType]
          apply_array_item_type_validation(type)
        end
      end

      # Apply validations for T::Tuple[...] types
      def apply_tuple_type_validations(tuple_type)
        # Apply standard array constraints (min_items, max_items, unique_items)
        apply_array_length_validation

        apply_unique_items_validation if @constraints[:unique_items]

        # Extract tuple types from the Tuple type
        item_types = tuple_type.types

        # Get additional_items from constraints
        additional_items = @constraints[:additional_items]

        apply_tuple_validations(item_types, additional_items)
      end

      # Apply tuple validation for arrays with positional type constraints
      def apply_tuple_validations(item_types, additional_items)
        prop_name = @property_name
        # Pre-resolve type classes for use in validate block
        resolved_item_types = item_types.map { |t| self.class.resolve_tuple_type_class(t) }
        resolved_additional_type = additional_items && [true, false].exclude?(additional_items) ? self.class.resolve_tuple_type_class(additional_items) : nil

        @klass.validate do |record|
          value = record.public_send(prop_name)
          next unless value.is_a?(Array)

          # Validate positional items
          resolved_item_types.each_with_index do |type_class, index|
            next if index >= value.length # Item not present (may be valid depending on minItems)

            item = value[index]
            next if ActiveModelAdapter.type_matches?(item, type_class)

            type_name = ActiveModelAdapter.type_name_for_error(type_class)
            record.errors.add(prop_name, "item at index #{index} must be a #{type_name}")
          end

          # Validate additional items constraint
          next unless value.length > resolved_item_types.length

          case additional_items
          when false
            record.errors.add(prop_name, "must have at most #{resolved_item_types.length} items")
          when nil, true
            # Any additional items allowed
          else
            # additional_items is a type - validate extra items against it
            value[resolved_item_types.length..].each_with_index do |item, offset|
              index = resolved_item_types.length + offset
              next if ActiveModelAdapter.type_matches?(item, resolved_additional_type)

              type_name = ActiveModelAdapter.type_name_for_error(resolved_additional_type)
              record.errors.add(prop_name, "item at index #{index} must be a #{type_name}")
            end
          end
        end
      end

      # Apply unique items validation for arrays using JSON Schema equality semantics
      def apply_unique_items_validation
        prop_name = @property_name
        @klass.validate do |record|
          value = record.public_send(prop_name)
          next unless value.is_a?(Array)

          record.errors.add(prop_name, 'must contain unique items') if JsonSchemaEquality.duplicates?(value)
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
          record.errors.add(prop_name, 'must be a boolean') if value && [true, false].exclude?(value)
        end
      end

      # Validate object/hash-specific constraints
      def apply_object_validations(expected_type)
        # Capture necessary variables outside the validation block's scope
        prop_name = @property_name

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

      # Plain data object holding pre-computed validation context.
      # All values are computed by ActiveModelAdapter and passed in,
      # avoiding tight coupling to adapter internals.
      class ValidationContext
        attr_reader :klass, :property_name, :constraints, :validation_type, :type_class, :model_class

        def initialize(attrs)
          @klass = attrs[:klass]
          @property_name = attrs[:property_name]
          @constraints = attrs[:constraints]
          @validation_type = attrs[:validation_type]
          @type_class = attrs[:type_class]
          @optional = attrs[:optional]
          @nilable = attrs[:nilable]

          # Derive additional flags from the pre-computed values
          @boolean_type = boolean_type_from_context?
          @array_type = array_type_from_context?
          @tuple_type = tuple_type_from_context?
          @model_class = model_class_from_context
        end

        def skip_presence_validation?
          @optional || @boolean_type || @nilable || @array_type
        end

        def array_requires_presence_validation?
          @array_type && !@nilable
        end

        def tuple_type?
          @tuple_type
        end

        def boolean?
          @boolean_type
        end

        private

        def boolean_type_from_context?
          TypeIntrospection.boolean_type?(@validation_type) ||
            @type_class == TrueClass ||
            @type_class == FalseClass ||
            TypeIntrospection.boolean_union_type?(@type_class)
        end

        def array_type_from_context?
          return false if @validation_type.nil?

          @validation_type == Array ||
            TypeIntrospection.typed_array?(@validation_type) ||
            tuple_type_from_context?
        end

        def tuple_type_from_context?
          defined?(EasyTalk::Types::Tuple) && @validation_type.is_a?(EasyTalk::Types::Tuple)
        end

        def model_class_from_context
          return unless @type_class.is_a?(Class)

          @type_class.include?(EasyTalk::Model) ? @type_class : nil
        end
      end

      # Shared min_items/max_items handling for array-like validations
      def apply_array_length_validation
        length_options = {
          minimum: @constraints[:min_items],
          maximum: @constraints[:max_items]
        }.compact

        return if length_options.empty?

        @klass.validates @property_name, length: length_options
      end

      private_constant :ValidationContext
    end
  end
end
