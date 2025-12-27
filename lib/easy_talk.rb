# frozen_string_literal: true

# The EasyTalk module is the main namespace for the gem.
module EasyTalk
  require 'sorbet-runtime'
  require 'easy_talk/sorbet_extension'
  require 'easy_talk/errors'
  require 'easy_talk/errors_helper'
  require 'easy_talk/configuration'
  require 'easy_talk/types/composer'

  # Validation adapters
  require 'easy_talk/validation_adapters/base'
  require 'easy_talk/validation_adapters/registry'
  require 'easy_talk/validation_adapters/active_model_adapter'
  require 'easy_talk/validation_adapters/none_adapter'

  require 'easy_talk/model'
  require 'easy_talk/schema'
  require 'easy_talk/property'
  require 'easy_talk/schema_definition'
  require 'easy_talk/validation_builder'
  require 'easy_talk/tools/function_builder'
  require 'easy_talk/version'

  # Register default validation adapters
  ValidationAdapters::Registry.register(:active_model, ValidationAdapters::ActiveModelAdapter)
  ValidationAdapters::Registry.register(:none, ValidationAdapters::NoneAdapter)

  def self.assert_valid_property_options(property_name, options, *valid_keys)
    valid_keys.flatten!
    options.each_key do |k|
      next if valid_keys.include?(k)

      ErrorHelper.raise_unknown_option_error(property_name: property_name, option: options, valid_options: valid_keys)
    end
  end

  def self.configure_nilable_behavior(nilable_is_optional = false)
    configuration.nilable_is_optional = nilable_is_optional
  end
end
