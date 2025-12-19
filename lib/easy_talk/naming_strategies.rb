# frozen_string_literal: true

module EasyTalk
  module NamingStrategies
    IDENTITY = lambda(&:to_sym)
    CAMEL_CASE = -> (property_name) { property_name.to_s.tr('-', '_').camelize(:lower).to_sym }
    PASCAL_CASE = -> (property_name) { property_name.to_s.tr('-', '_').camelize.to_sym }
  end
end
