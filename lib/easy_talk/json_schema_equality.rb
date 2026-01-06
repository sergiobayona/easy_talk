# frozen_string_literal: true

module EasyTalk
  # Implements JSON Schema equality semantics for comparing values.
  #
  # Per JSON Schema specification:
  # - Objects with same keys/values in different order are equal
  # - Numbers that are mathematically equal are equal (1 == 1.0)
  # - Type matters for non-numbers (true != 1, false != 0)
  module JsonSchemaEquality
    # Maximum nesting depth to prevent SystemStackError on deeply nested structures
    MAX_DEPTH = 100

    class << self
      # Check if an array contains duplicate values using JSON Schema equality.
      # Uses a Set for O(n) performance and early termination on first duplicate.
      def duplicates?(array)
        seen = Set.new
        array.any? { |item| !seen.add?(normalize(item)) }
      end

      # Normalize a value for JSON Schema equality comparison
      # @param value [Object] The value to normalize
      # @param depth [Integer] Current recursion depth (for stack overflow protection)
      # @raise [ArgumentError] if nesting depth exceeds MAX_DEPTH
      def normalize(value, depth = 0)
        raise ArgumentError, "Nesting depth exceeds maximum of #{MAX_DEPTH}" if depth > MAX_DEPTH

        case value
        when Hash
          # Sort keys and recursively normalize values for order-independent comparison
          value.sort.map { |k, v| [k, normalize(v, depth + 1)] }
        when Array
          value.map { |item| normalize(item, depth + 1) }
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
