require_relative 'keywords'

module EsquemaBase
  class OptionsNormalizer
    class << self
      def normalize(options)
        options.each_with_object({}) do |(key, value), hash|
          raise UnsupportedConstraintError, "Unsupported constraint: #{key}" unless KEYWORDS.include?(key.to_sym)

          valid_key = KEYWORDS[key.to_sym]
          hash[valid_key] = value
        end
      end
    end
  end
end
