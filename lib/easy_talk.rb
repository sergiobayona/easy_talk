# frozen_string_literal: true

# The EasyTalk module is the main namespace for the gem.
module EasyTalk
  require 'sorbet-runtime'
  require 'easy_talk/sorbet_extension'
  require 'easy_talk/errors'
  require 'easy_talk/type_introspection'
  require 'easy_talk/errors_helper'
  require 'easy_talk/configuration'
  require 'easy_talk/schema_methods'
  require 'easy_talk/types/composer'
  require 'easy_talk/types/tuple'
  require "easy_talk/active_model_type"

  # Validation adapters
  require 'easy_talk/validation_adapters/base'
  require 'easy_talk/validation_adapters/registry'
  require 'easy_talk/validation_adapters/active_model_adapter'
  require 'easy_talk/validation_adapters/none_adapter'

  # Builder registry for pluggable type support
  require 'easy_talk/builders/registry'

  require 'easy_talk/model'
  require 'easy_talk/schema'
  require 'easy_talk/property'
  require 'easy_talk/schema_definition'
  require 'easy_talk/validation_builder'
  require 'easy_talk/error_formatter'
  require 'easy_talk/tools/function_builder'
  require 'easy_talk/version'

  # Register default validation adapters
  ValidationAdapters::Registry.register_default_adapters

  # Register built-in type builders
  Builders::Registry.register_built_in_types

  # Register a custom type with its corresponding schema builder.
  #
  # This allows extending EasyTalk with domain-specific types without
  # modifying the gem's source code.
  #
  # @param type_key [Class, String, Symbol] The type to register
  # @param builder_class [Class] The builder class that generates JSON Schema
  # @param collection [Boolean] Whether this is a collection type builder
  #   Collection builders receive (name, type, constraints) instead of (name, constraints)
  # @return [void]
  #
  # @example Register a custom Money type
  #   EasyTalk.register_type(Money, MoneySchemaBuilder)
  #
  # @example Register a collection type
  #   EasyTalk.register_type(CustomArray, CustomArrayBuilder, collection: true)
  def self.register_type(type_key, builder_class, collection: false)
    Builders::Registry.register(type_key, builder_class, collection: collection)
  end

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
