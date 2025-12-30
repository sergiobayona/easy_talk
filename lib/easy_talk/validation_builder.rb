# frozen_string_literal: true
# typed: true

module EasyTalk
  # @deprecated Use EasyTalk::ValidationAdapters::ActiveModelAdapter instead.
  #
  # The ValidationBuilder class is kept for backward compatibility.
  # It delegates to the ActiveModelAdapter and shows a deprecation warning.
  #
  # This class will be removed in a future major version.
  #
  # @example Migration
  #   # Before (deprecated)
  #   EasyTalk::ValidationBuilder.build_validations(klass, :name, String, {})
  #
  #   # After (recommended)
  #   EasyTalk::ValidationAdapters::ActiveModelAdapter.build_validations(klass, :name, String, {})
  #
  class ValidationBuilder
    @deprecation_warned = false

    # Build validations for a property and apply them to the model class.
    #
    # @deprecated Use EasyTalk::ValidationAdapters::ActiveModelAdapter.build_validations instead.
    # @param klass [Class] The model class to apply validations to
    # @param property_name [Symbol, String] The name of the property
    # @param type [Class, Object] The type of the property
    # @param constraints [Hash] The JSON Schema constraints for the property
    # @return [void]
    def self.build_validations(klass, property_name, type, constraints)
      unless @deprecation_warned
        warn "[DEPRECATION] EasyTalk::ValidationBuilder is deprecated and will be removed in a future version. " \
             "Use EasyTalk::ValidationAdapters::ActiveModelAdapter instead."
        @deprecation_warned = true
      end

      ValidationAdapters::ActiveModelAdapter.build_validations(klass, property_name, type, constraints)
    end

    # Reset the deprecation warning flag (useful for testing).
    #
    # @api private
    def self.reset_deprecation_warning!
      @deprecation_warned = false
    end
  end
end
