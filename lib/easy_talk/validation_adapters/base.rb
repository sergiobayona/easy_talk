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

      # Build schema-level validations (e.g., min_properties, max_properties, dependent_required).
      # Subclasses can override this method to implement schema-level validations.
      #
      # @param klass [Class] The model class to apply validations to
      # @param schema [Hash] The full schema hash containing schema-level constraints
      # @return [void]
      def self.build_schema_validations(klass, schema)
        # Default implementation does nothing - subclasses can override
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
      # Delegates to TypeIntrospection.
      #
      # @param type_to_check [Class, Object] The type to check (defaults to @type)
      # @return [Boolean] true if the type is nilable
      def nilable_type?(type_to_check = @type)
        TypeIntrospection.nilable_type?(type_to_check)
      end

      # Extract the inner type from a complex type like T.nilable(String) or T.nilable(T::Array[Model]).
      # Delegates to TypeIntrospection.
      #
      # @param type_to_unwrap [Class, Object] The type to unwrap (defaults to @type)
      # @return [Class, Object] The inner type, or the original type if not wrapped
      def extract_inner_type(type_to_unwrap = @type)
        TypeIntrospection.extract_inner_type(type_to_unwrap)
      end

      # Determine the actual class for a type, handling Sorbet types.
      # Delegates to TypeIntrospection.
      #
      # @param type_to_resolve [Class, Object] The type to resolve
      # @return [Class, Array<Class>] The resolved class or classes
      def get_type_class(type_to_resolve)
        TypeIntrospection.get_type_class(type_to_resolve)
      end
    end
  end
end
