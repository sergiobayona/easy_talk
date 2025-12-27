# frozen_string_literal: true

module EasyTalk
  module ValidationAdapters
    # No-op validation adapter.
    #
    # This adapter does not apply any validations. Use it when you want
    # schema generation without any validation side effects.
    #
    # @example Disabling validations for a model
    #   class ApiContract
    #     include EasyTalk::Model
    #
    #     define_schema(validations: :none) do
    #       property :name, String, min_length: 5
    #     end
    #   end
    #
    #   contract = ApiContract.new(name: 'X')
    #   contract.valid? # => true (no validations applied)
    #
    # @example Using globally
    #   EasyTalk.configure do |config|
    #     config.validation_adapter = :none
    #   end
    #
    class NoneAdapter < Base
      # Apply no validations (no-op).
      #
      # @return [void]
      def apply_validations
        # Intentionally empty - no validations applied
      end
    end
  end
end
