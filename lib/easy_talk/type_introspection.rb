# frozen_string_literal: true
# typed: true

require 'bigdecimal'

module EasyTalk
  # Centralized module for robust type introspection.
  #
  # This module provides predicate methods for detecting types without relying
  # on brittle string-based checks. It uses Sorbet's type system properly and
  # handles edge cases gracefully.
  #
  # @example Checking if a type is boolean
  #   TypeIntrospection.boolean_type?(T::Boolean) # => true
  #   TypeIntrospection.boolean_type?(TrueClass)  # => true
  #   TypeIntrospection.boolean_type?(String)     # => false
  #
  # @example Getting JSON Schema type
  #   TypeIntrospection.json_schema_type(Integer) # => 'integer'
  #   TypeIntrospection.json_schema_type(Float)   # => 'number'
  #
  module TypeIntrospection
    # Mapping of Ruby classes to JSON Schema types
    PRIMITIVE_TO_JSON_SCHEMA = {
      String => 'string',
      Integer => 'integer',
      Float => 'number',
      BigDecimal => 'number',
      TrueClass => 'boolean',
      FalseClass => 'boolean',
      NilClass => 'null'
    }.freeze

    class << self
      extend T::Sig

      # Check if type represents a boolean (T::Boolean or TrueClass/FalseClass).
      #
      # @param type [Object] The type to check
      # @return [Boolean] true if the type is a boolean type
      #
      # @example
      #   boolean_type?(T::Boolean)  # => true
      #   boolean_type?(TrueClass)   # => true
      #   boolean_type?(FalseClass)  # => true
      #   boolean_type?(String)      # => false
      sig { params(type: T.untyped).returns(T::Boolean) }
      def boolean_type?(type)
        return false if type.nil?
        return true if [TrueClass, FalseClass].include?(type)
        return true if type.respond_to?(:raw_type) && [TrueClass, FalseClass].include?(type.raw_type)

        # Check for T::Boolean which is a TypeAlias with name 'T::Boolean'
        return true if type.respond_to?(:name) && type.name == 'T::Boolean'

        # Check for union types containing TrueClass and FalseClass
        if type.respond_to?(:types)
          type_classes = type.types.map { |t| t.respond_to?(:raw_type) ? t.raw_type : t }
          return type_classes.sort_by(&:name) == [FalseClass, TrueClass].sort_by(&:name)
        end

        false
      end

      # Check if type is a typed array (T::Array[...]).
      #
      # @param type [Object] The type to check
      # @return [Boolean] true if the type is a typed array
      #
      # @example
      #   typed_array?(T::Array[String]) # => true
      #   typed_array?(Array)            # => false
      sig { params(type: T.untyped).returns(T::Boolean) }
      def typed_array?(type)
        return false if type.nil?

        type.is_a?(T::Types::TypedArray)
      end

      # Check if type is nilable (T.nilable(...)).
      #
      # @param type [Object] The type to check
      # @return [Boolean] true if the type is nilable
      #
      # @example
      #   nilable_type?(T.nilable(String)) # => true
      #   nilable_type?(String)            # => false
      sig { params(type: T.untyped).returns(T::Boolean) }
      def nilable_type?(type)
        return false if type.nil?

        type.respond_to?(:nilable?) && type.nilable?
      end

      # Check if type is a primitive Ruby type.
      #
      # @param type [Object] The type to check
      # @return [Boolean] true if the type is a primitive
      sig { params(type: T.untyped).returns(T::Boolean) }
      def primitive_type?(type)
        return false if type.nil?

        resolved = if type.is_a?(Class)
                     type
                   elsif type.respond_to?(:raw_type)
                     type.raw_type
                   end
        PRIMITIVE_TO_JSON_SCHEMA.key?(resolved)
      end

      # Get JSON Schema type string for a Ruby type.
      #
      # @param type [Object] The type to convert
      # @return [String] The JSON Schema type string
      #
      # @example
      #   json_schema_type(Integer)    # => 'integer'
      #   json_schema_type(Float)      # => 'number'
      #   json_schema_type(BigDecimal) # => 'number'
      #   json_schema_type(String)     # => 'string'
      sig { params(type: T.untyped).returns(String) }
      def json_schema_type(type)
        return 'object' if type.nil?
        return 'boolean' if boolean_type?(type)

        resolved_class = if type.is_a?(Class)
                           type
                         elsif type.respond_to?(:raw_type)
                           type.raw_type
                         end

        PRIMITIVE_TO_JSON_SCHEMA[resolved_class] || resolved_class&.name&.downcase || 'object'
      end

      # Get the Ruby class for a type, handling Sorbet types.
      #
      # @param type [Object] The type to resolve
      # @return [Class, Array<Class>, nil] The resolved class or classes
      #
      # @example
      #   get_type_class(String)           # => String
      #   get_type_class(T::Boolean)       # => [TrueClass, FalseClass]
      #   get_type_class(T::Array[String]) # => Array
      sig { params(type: T.untyped).returns(T.untyped) }
      def get_type_class(type)
        return nil if type.nil?
        return type if type.is_a?(Class)
        return type.raw_type if type.respond_to?(:raw_type)
        return Array if typed_array?(type)
        return [TrueClass, FalseClass] if boolean_type?(type)

        if nilable_type?(type)
          inner = extract_inner_type(type)
          return get_type_class(inner) if inner && inner != type
        end

        nil
      end

      # Extract inner type from nilable or complex types.
      #
      # @param type [Object] The type to unwrap
      # @return [Object] The inner type, or the original type if not wrapped
      #
      # @example
      #   extract_inner_type(T.nilable(String)) # => String
      sig { params(type: T.untyped).returns(T.untyped) }
      def extract_inner_type(type)
        return type if type.nil?

        if type.respond_to?(:unwrap_nilable)
          unwrapped = type.unwrap_nilable
          return unwrapped.respond_to?(:raw_type) ? unwrapped.raw_type : unwrapped
        end

        if type.respond_to?(:types)
          non_nil = type.types.find do |t|
            raw = t.respond_to?(:raw_type) ? t.raw_type : t
            raw != NilClass
          end
          return non_nil.respond_to?(:raw_type) ? non_nil.raw_type : non_nil if non_nil
        end

        type
      end
    end
  end
end
