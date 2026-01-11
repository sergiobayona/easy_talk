# frozen_string_literal: true
# typed: true

require_relative 'naming_strategies'

module EasyTalk
  class Configuration
    extend T::Sig

    # JSON Schema draft version URIs
    SCHEMA_VERSIONS = {
      draft202012: 'https://json-schema.org/draft/2020-12/schema',
      draft201909: 'https://json-schema.org/draft/2019-09/schema',
      draft7: 'http://json-schema.org/draft-07/schema#',
      draft6: 'http://json-schema.org/draft-06/schema#',
      draft4: 'http://json-schema.org/draft-04/schema#'
    }.freeze

    attr_accessor :default_additional_properties, :nilable_is_optional, :auto_validations, :schema_version, :schema_id,
                  :use_refs, :validation_adapter, :default_error_format, :error_type_base_uri, :include_error_codes,
                  :base_schema_uri, :auto_generate_ids, :prefer_external_refs
    attr_reader :property_naming_strategy

    sig { void }
    def initialize
      @default_additional_properties = false
      @nilable_is_optional = false
      @auto_validations = true
      @validation_adapter = :active_model
      @schema_version = :none
      @schema_id = nil
      @use_refs = false
      @default_error_format = :flat
      @error_type_base_uri = 'about:blank'
      @include_error_codes = true
      @base_schema_uri = nil
      @auto_generate_ids = false
      @prefer_external_refs = false
      self.property_naming_strategy = :identity
    end

    # Returns the URI for the configured schema version, or nil if :none
    sig { returns(T.nilable(String)) }
    def schema_uri
      return nil if @schema_version == :none

      SCHEMA_VERSIONS[@schema_version] || @schema_version.to_s
    end

    sig { params(strategy: T.any(Symbol, T.proc.params(arg0: T.untyped).returns(Symbol))).void }
    def property_naming_strategy=(strategy)
      @property_naming_strategy = EasyTalk::NamingStrategies.derive_strategy(strategy)
    end

    # Register a custom type with its corresponding schema builder.
    #
    # This convenience method delegates to Builders::Registry.register
    # and allows type registration within a configuration block.
    #
    # @param type_key [Class, String, Symbol] The type to register
    # @param builder_class [Class] The builder class that generates JSON Schema
    # @param collection [Boolean] Whether this is a collection type builder
    # @return [void]
    #
    # @example
    #   EasyTalk.configure do |config|
    #     config.register_type Money, MoneySchemaBuilder
    #   end
    sig { params(type_key: T.any(T::Class[T.anything], String, Symbol), builder_class: T.untyped, collection: T::Boolean).void }
    def register_type(type_key, builder_class, collection: false)
      EasyTalk::Builders::Registry.register(type_key, builder_class, collection: collection)
    end
  end

  class << self
    extend T::Sig

    sig { returns(Configuration) }
    def configuration
      @configuration ||= Configuration.new
    end

    sig { params(block: T.proc.params(config: Configuration).void).void }
    def configure(&block)
      yield(configuration)
    end
  end
end
