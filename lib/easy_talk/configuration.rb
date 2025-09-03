# frozen_string_literal: true

module EasyTalk
  class Configuration
    attr_accessor :default_additional_properties, :nilable_is_optional, :auto_validations

    def initialize
      @default_additional_properties = false
      @nilable_is_optional = false
      @auto_validations = true
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
