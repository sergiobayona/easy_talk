module EasyTalk
  class Configuration
    attr_accessor :exclude_foreign_keys, :exclude_associations, :excluded_columns,
                  :exclude_primary_key, :exclude_timestamps, :default_additional_properties

    def initialize
      @exclude_foreign_keys = true
      @exclude_associations = true
      @excluded_columns = []
      @exclude_primary_key = true  # New option, defaulting to true
      @exclude_timestamps = true   # New option, defaulting to true
      @default_additional_properties = false
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
