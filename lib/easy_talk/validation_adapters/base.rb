# frozen_string_literal: true

module EasyTalk
  module ValidationAdapters
    # Abstract base class for validation adapters.
    #
    # Validation adapters are responsible for converting JSON Schema constraints
    # into validation rules for the target validation framework (e.g., ActiveModel,
    # dry-validation, or custom validators).
    #
    # To create a custom adapter, subclass this class and implement the
    # `apply_validations` method.
    #
    # @example Creating a custom adapter
    #   class MyCustomAdapter < EasyTalk::ValidationAdapters::Base
    #     def apply_validations
    #       # Apply custom validations to @klass based on @constraints
    #       @klass.validates @property_name, presence: true unless optional?
    #     end
    #   end
    #
    # @example Registering and using a custom adapter
    #   EasyTalk::ValidationAdapters::Registry.register(:custom, MyCustomAdapter)
    #
    #   class User
    #     include EasyTalk::Model
    #     define_schema(validations: :custom) do
    #       property :name, String
    #     end
    #   end
    #
    class Base
      # Build validations for a property and apply them to the model class.
      # This is the primary interface that adapters must implement.
      #
      # @param klass [Class] The model class to apply validations to
      # @param property_name [Symbol, String] The name of the property
      # @param type [Class, Object] The type of the property (Ruby class or Sorbet type)
      # @param constraints [Hash] The JSON Schema constraints for the property
      #   Possible keys: :min_length, :max_length, :minimum, :maximum, :pattern,
      #   :format, :enum, :const, :min_items, :max_items, :unique_items, :optional
      # @return [void]
      def self.build_validations(klass, property_name, type, constraints)
        new(klass, property_name, type, constraints).apply_validations
      end

      # Initialize a new validation adapter instance.
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

      # Apply validations based on property type and constraints.
      # Subclasses MUST implement this method.
      #
      # @abstract
      # @return [void]
      # @raise [NotImplementedError] if the subclass does not implement this method
      def apply_validations
        raise NotImplementedError, "#{self.class} must implement #apply_validations"
      end

      protected

      attr_reader :klass, :property_name, :type, :constraints

      # Check if a property is optional based on constraints and configuration.
      #
      # A property is considered optional if:
      # - The :optional constraint is explicitly set to true
      # - The type is nilable AND nilable_is_optional configuration is true
      #
      # @return [Boolean] true if the property is optional
      def optional?
        @constraints[:optional] == true ||
          (@type.respond_to?(:nilable?) && @type.nilable? && EasyTalk.configuration.nilable_is_optional)
      end

      # Check if the type is nilable (e.g., T.nilable(String)).
      #
      # @param t [Class, Object] The type to check (defaults to @type)
      # @return [Boolean] true if the type is nilable
      def nilable_type?(type_to_check = @type)
        type_to_check.respond_to?(:nilable?) && type_to_check.nilable?
      end

      # Extract the inner type from a complex type like T.nilable(String).
      #
      # @param type_to_unwrap [Class, Object] The type to unwrap (defaults to @type)
      # @return [Class, Object] The inner type, or the original type if not wrapped
      def extract_inner_type(type_to_unwrap = @type)
        if type_to_unwrap.respond_to?(:unwrap_nilable) && type_to_unwrap.unwrap_nilable.respond_to?(:raw_type)
          type_to_unwrap.unwrap_nilable.raw_type
        elsif type_to_unwrap.respond_to?(:types)
          # For union types like T.nilable(String), extract the non-nil type
          type_to_unwrap.types.find { |inner| inner.respond_to?(:raw_type) && inner.raw_type != NilClass }
        else
          type_to_unwrap
        end
      end

      # Determine the actual class for a type, handling Sorbet types.
      #
      # @param type_to_resolve [Class, Object] The type to resolve
      # @return [Class, Array<Class>] The resolved class or classes
      def get_type_class(type_to_resolve)
        if type_to_resolve.is_a?(Class)
          type_to_resolve
        elsif type_to_resolve.respond_to?(:raw_type)
          type_to_resolve.raw_type
        elsif type_to_resolve.is_a?(T::Types::TypedArray)
          Array
        elsif type_to_resolve.is_a?(Symbol) || type_to_resolve.is_a?(String)
          begin
            type_to_resolve.to_s.classify.constantize
          rescue StandardError
            String
          end
        elsif TypeIntrospection.boolean_type?(type_to_resolve)
          [TrueClass, FalseClass]
        elsif nilable_type?(type_to_resolve)
          extract_inner_type(type_to_resolve)
        else
          String
        end
      end
    end
  end
end
