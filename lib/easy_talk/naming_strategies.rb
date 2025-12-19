# frozen_string_literal: true

module EasyTalk
  module NamingStrategies
    IDENTITY = lambda(&:to_sym)
    CAMEL_CASE = -> (property_name) { property_name.to_s.tr('-', '_').camelize(:lower).to_sym }
    PASCAL_CASE = -> (property_name) { property_name.to_s.tr('-', '_').camelize.to_sym }

    def self.derive_strategy(strategy)
      if strategy.is_a?(Symbol)
        "EasyTalk::NamingStrategies::#{strategy.to_s.upcase}".constantize
      elsif strategy.is_a?(Proc)
        strategy
      else
        raise ArgumentError, 'Invalid property naming strategy. Must be a Symbol or a Proc.'
      end
    end
  end
end
