# frozen_string_literal: true
# typed: true

module EasyTalk
  module NamingStrategies
    extend T::Sig

    IDENTITY = lambda(&:to_sym)
    SNAKE_CASE = ->(property_name) { property_name.to_s.underscore.to_sym }
    CAMEL_CASE = ->(property_name) { property_name.to_s.tr('-', '_').camelize(:lower).to_sym }
    PASCAL_CASE = ->(property_name) { property_name.to_s.tr('-', '_').camelize.to_sym }

    sig { params(strategy: T.any(Symbol, T.proc.params(arg0: T.untyped).returns(Symbol))).returns(T.proc.params(arg0: T.untyped).returns(Symbol)) }
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
