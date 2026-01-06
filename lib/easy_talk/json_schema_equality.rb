# frozen_string_literal: true

module EasyTalk
  # Implements JSON Schema equality semantics for comparing values.
  #
  # Per JSON Schema specification:
  # - Objects with same keys/values in different order are equal
  # - Numbers that are mathematically equal are equal (1 == 1.0)
  # - Type matters for non-numbers (true != 1, false != 0)
  module JsonSchemaEquality
    class << self
      # Check if an array contains duplicate values using JSON Schema equality
      def duplicates?(array)
        normalized = array.map { |item| normalize(item) }
        normalized.uniq.length != normalized.length
      end

      # Normalize a value for JSON Schema equality comparison
      def normalize(value)
        case value
        when Hash
          # Sort keys and recursively normalize values for order-independent comparison
          value.sort.map { |k, v| [k, normalize(v)] }
        when Array
          value.map { |item| normalize(item) }
        when Integer, Float
          # Normalize numbers to a canonical form for mathematical equality
          value.to_r
        else
          # Booleans, strings, nil - preserve as-is (type matters)
          value
        end
      end
    end
  end
end
