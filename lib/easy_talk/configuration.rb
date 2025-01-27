module EasyTalk
  class Configuration
    attr_accessor :exclude_foreign_keys, :exclude_associations, :excluded_columns

    def initialize
      @exclude_foreign_keys = false
      @exclude_associations = false
      @excluded_columns = []
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
