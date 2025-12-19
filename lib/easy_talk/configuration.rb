# frozen_string_literal: true
require_relative 'naming_strategies'

module EasyTalk
  class Configuration
    # JSON Schema draft version URIs
    SCHEMA_VERSIONS = {
      draft202012: 'https://json-schema.org/draft/2020-12/schema',
      draft201909: 'https://json-schema.org/draft/2019-09/schema',
      draft7: 'http://json-schema.org/draft-07/schema#',
      draft6: 'http://json-schema.org/draft-06/schema#',
      draft4: 'http://json-schema.org/draft-04/schema#'
    }.freeze

    attr_accessor :default_additional_properties, :nilable_is_optional, :auto_validations, :schema_version, :schema_id,
                  :use_refs
    attr_reader :property_naming_strategy

    def initialize
      @default_additional_properties = false
      @nilable_is_optional = false
      @auto_validations = true
      @schema_version = :none
      @schema_id = nil
      @use_refs = false
      self.property_naming_strategy = :identity
    end

    # Returns the URI for the configured schema version, or nil if :none
    def schema_uri
      return nil if @schema_version == :none

      SCHEMA_VERSIONS[@schema_version] || @schema_version.to_s
    end

    def property_naming_strategy=(strategy)
      @property_naming_strategy = if strategy.is_a?(Symbol)
                                    "EasyTalk::NamingStrategies::#{strategy.to_s.upcase}".constantize
                                  elsif strategy.is_a?(Proc)
                                    strategy
                                  else
                                    raise ArgumentError, 'Invalid property naming strategy. Must be a Symbol or a Proc.'
                                  end
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
