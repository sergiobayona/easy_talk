# frozen_string_literal: true

module EasyTalk
  module ValidationAdapters
    # Registry for validation adapters.
    #
    # The registry allows adapters to be registered with symbolic names and
    # resolved from various input types (symbols, classes, or nil for default).
    #
    # @example Registering an adapter
    #   EasyTalk::ValidationAdapters::Registry.register(:custom, MyCustomAdapter)
    #
    # @example Resolving an adapter
    #   adapter = EasyTalk::ValidationAdapters::Registry.resolve(:active_model)
    #   adapter.build_validations(klass, :name, String, {})
    #
    class Registry
      class << self
        # Get the hash of registered adapters.
        #
        # @return [Hash{Symbol => Class}] The registered adapters
        def adapters
          @adapters ||= {}
        end

        # Register an adapter with a symbolic name.
        #
        # @param name [Symbol, String] The adapter identifier
        # @param adapter_class [Class] The adapter class (must respond to .build_validations)
        # @raise [ArgumentError] if the adapter does not respond to .build_validations
        # @return [void]
        def register(name, adapter_class)
          raise ArgumentError, "Adapter must respond to .build_validations" unless adapter_class.respond_to?(:build_validations)

          adapters[name.to_sym] = adapter_class
        end

        # Resolve an adapter from various input types.
        #
        # @param adapter [Symbol, Class, nil] The adapter identifier or class
        #   - nil: returns the default :active_model adapter
        #   - Symbol: looks up the adapter by name in the registry
        #   - Class: returns the class directly (assumes it implements the adapter interface)
        # @return [Class] The adapter class
        # @raise [ArgumentError] if the adapter symbol is not registered or type is invalid
        def resolve(adapter)
          case adapter
          when nil
            adapters[:active_model] || raise(ArgumentError, "No default adapter registered")
          when Symbol
            adapters[adapter] || raise(ArgumentError, "Unknown validation adapter: #{adapter.inspect}")
          when Class
            adapter
          else
            raise ArgumentError, "Invalid adapter type: #{adapter.class}. Expected Symbol, Class, or nil."
          end
        end

        # Check if an adapter is registered with the given name.
        #
        # @param name [Symbol, String] The adapter name to check
        # @return [Boolean] true if the adapter is registered
        def registered?(name)
          adapters.key?(name.to_sym)
        end

        # Reset the registry (useful for testing).
        #
        # @return [void]
        def reset!
          @adapters = nil
        end
      end
    end
  end
end
