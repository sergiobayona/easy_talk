# frozen_string_literal: true

module EasyTalk
  class Configuration
    attr_accessor :exclude_foreign_keys, :exclude_associations, :excluded_columns,
                  :exclude_primary_key, :exclude_timestamps, :default_additional_properties,
                  :nilable_is_optional, :auto_validations

    def initialize
      @exclude_foreign_keys = true
      @exclude_associations = true
      @excluded_columns = []
      @exclude_primary_key = true
      @exclude_timestamps = true
      @default_additional_properties = false
      @nilable_is_optional = false
      @auto_validations = true # New option: enable validations by default
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
