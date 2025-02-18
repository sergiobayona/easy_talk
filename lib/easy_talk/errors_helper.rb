module EasyTalk
  module ErrorHelper
    def self.raise_constraint_error(property:, key:, expected:, got:)
      message = "Error in property '#{property}': Constraint '#{key}' expects #{expected}, " \
                "but received #{got.inspect} (#{got.class})."
      raise ConstraintError, message
    end

    def self.raise_unknown_option_error(property:, option:, valid_options:)
      message = "Unknown option '#{option}' for property '#{property}'. " \
                "Valid options are: #{valid_options.join(', ')}."
      raise UnknownOptionError, message
    end
  end
end
