# frozen_string_literal: true
# typed: true

module EasyTalk
  module Builders
    # Registry for type-to-builder mappings.
    #
    # The registry allows custom types to be registered with their corresponding
    # schema builder classes at runtime, without modifying the gem's source code.
    #
    # Custom registrations take priority over built-in types, allowing users to
    # override default behavior when needed.
    #
    # @example Registering a custom type
    #   EasyTalk::Builders::Registry.register(Money, MoneySchemaBuilder)
    #
    # @example Registering a collection type
    #   EasyTalk::Builders::Registry.register(CustomArray, CustomArrayBuilder, collection: true)
    #
    # @example Resolving a builder for a type
    #   builder_class, is_collection = EasyTalk::Builders::Registry.resolve(Money)
    #   builder_class.new(name, constraints).build
    #
    class Registry
      class << self
        extend T::Sig

        # Get the hash of registered type builders.
        #
        # @return [Hash{String => Hash}] The registered builders with metadata
        sig { returns(T::Hash[String, T::Hash[Symbol, T.untyped]]) }
        def registry
          @registry ||= {}
        end

        # Register a type with its corresponding builder class.
        #
        # @param type_key [Class, String, Symbol] The type identifier
        # @param builder_class [Class] The builder class (must respond to .new)
        # @param collection [Boolean] Whether this is a collection type builder
        #   Collection builders receive (name, type, constraints) instead of (name, constraints)
        # @raise [ArgumentError] if the builder does not respond to .new
        # @return [void]
        #
        # @example Register a simple type
        #   Registry.register(Money, MoneySchemaBuilder)
        #
        # @example Register a collection type
        #   Registry.register(CustomArray, CustomArrayBuilder, collection: true)
        sig { params(type_key: T.any(T::Class[T.anything], String, Symbol), builder_class: T.untyped, collection: T::Boolean).void }
        def register(type_key, builder_class, collection: false)
          raise ArgumentError, 'Builder must respond to .new' unless builder_class.respond_to?(:new)

          key = normalize_key(type_key)
          registry[key] = { builder: builder_class, collection: collection }
        end

        # Resolve a builder for the given type.
        #
        # Resolution order:
        # 1. Check type.class.name (e.g., "T::Types::TypedArray")
        # 2. Check type.name if type responds to :name (e.g., "String")
        # 3. Check type itself if it's a Class (e.g., String class)
        #
        # @param type [Object] The type to find a builder for
        # @return [Array(Class, Boolean), nil] A tuple of [builder_class, is_collection] or nil if not found
        #
        # @example
        #   builder_class, is_collection = Registry.resolve(String)
        #   # => [StringBuilder, false]
        sig { params(type: T.untyped).returns(T.nilable(T::Array[T.untyped])) }
        def resolve(type)
          entry = find_registration(type)
          return nil unless entry

          [entry[:builder], entry[:collection]]
        end

        # Check if a type is registered.
        #
        # @param type_key [Class, String, Symbol] The type to check
        # @return [Boolean] true if the type is registered
        sig { params(type_key: T.any(T::Class[T.anything], String, Symbol)).returns(T::Boolean) }
        def registered?(type_key)
          registry.key?(normalize_key(type_key))
        end

        # Unregister a type.
        #
        # @param type_key [Class, String, Symbol] The type to unregister
        # @return [Hash, nil] The removed registration or nil if not found
        sig { params(type_key: T.any(T::Class[T.anything], String, Symbol)).returns(T.nilable(T::Hash[Symbol, T.untyped])) }
        def unregister(type_key)
          registry.delete(normalize_key(type_key))
        end

        # Get a list of all registered type keys.
        #
        # @return [Array<String>] The registered type keys
        sig { returns(T::Array[String]) }
        def registered_types
          registry.keys
        end

        # Reset the registry to empty state and re-register built-in types.
        #
        # @return [void]
        sig { void }
        def reset!
          @registry = nil
          register_built_in_types
        end

        # Register all built-in type builders.
        # This is called during gem initialization and after reset!
        #
        # @return [void]
        sig { void }
        def register_built_in_types
          register(String, Builders::StringBuilder)
          register(Integer, Builders::IntegerBuilder)
          register(Float, Builders::NumberBuilder)
          register(BigDecimal, Builders::NumberBuilder)
          register('T::Boolean', Builders::BooleanBuilder)
          register(TrueClass, Builders::BooleanBuilder)
          register(NilClass, Builders::NullBuilder)
          register(Date, Builders::TemporalBuilder::DateBuilder)
          register(DateTime, Builders::TemporalBuilder::DatetimeBuilder)
          register(Time, Builders::TemporalBuilder::TimeBuilder)
          register('allOf', Builders::CompositionBuilder::AllOfBuilder, collection: true)
          register('anyOf', Builders::CompositionBuilder::AnyOfBuilder, collection: true)
          register('oneOf', Builders::CompositionBuilder::OneOfBuilder, collection: true)
          register('EasyTalk::Types::Tuple', Builders::TupleBuilder, collection: true)
          register('T::Types::TypedArray', Builders::TypedArrayBuilder, collection: true)
          register('T::Types::Union', Builders::UnionBuilder, collection: true)
        end

        private

        # Normalize a type key to a canonical string form.
        #
        # @param type_key [Class, String, Symbol] The type key to normalize
        # @return [String] The normalized key
        sig { params(type_key: T.any(T::Class[T.anything], String, Symbol)).returns(String) }
        def normalize_key(type_key)
          case type_key
          when Class
            type_key.name.to_s
          when Symbol
            type_key.to_s
          else
            type_key.to_s
          end
        end

        # Find a registration for the given type.
        #
        # Tries multiple resolution strategies in order.
        #
        # @param type [Object] The type to find
        # @return [Hash, nil] The registration entry or nil
        sig { params(type: T.untyped).returns(T.nilable(T::Hash[Symbol, T.untyped])) }
        def find_registration(type)
          # Strategy 1: Check type.class.name (for Sorbet types like T::Types::TypedArray)
          class_name = type.class.name.to_s
          return registry[class_name] if registry.key?(class_name)

          # Strategy 2: Check type.name (for types that respond to :name, like "String")
          if type.respond_to?(:name)
            type_name = type.name.to_s
            return registry[type_name] if registry.key?(type_name)
          end

          # Strategy 3: Check the type itself if it's a Class
          return registry[type.name.to_s] if type.is_a?(Class) && registry.key?(type.name.to_s)

          nil
        end
      end
    end
  end
end
