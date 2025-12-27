# frozen_string_literal: true

module EasyTalk
  module ErrorFormatter
    # Converts attribute paths between different formats.
    #
    # EasyTalk uses dot notation for nested model errors (e.g., "email.address").
    # This class converts those paths to different standard formats:
    # - JSON Pointer (RFC 6901): /properties/email/properties/address
    # - JSON:API: /data/attributes/email/address
    # - Flat: email.address (unchanged)
    #
    # @example
    #   PathConverter.to_json_pointer("email.address")
    #   # => "/properties/email/properties/address"
    #
    #   PathConverter.to_jsonapi_pointer("email.address")
    #   # => "/data/attributes/email/address"
    #
    class PathConverter
      class << self
        # Convert an attribute path to JSON Schema pointer format.
        #
        # @param attribute [Symbol, String] The attribute path (e.g., "email.address")
        # @return [String] The JSON Pointer path (e.g., "/properties/email/properties/address")
        def to_json_pointer(attribute)
          parts = attribute.to_s.split('.')
          return "/properties/#{parts.first}" if parts.length == 1

          parts.map { |part| "/properties/#{part}" }.join
        end

        # Convert an attribute path to JSON:API pointer format.
        #
        # @param attribute [Symbol, String] The attribute path
        # @param prefix [String] The path prefix (default: "/data/attributes")
        # @return [String] The JSON:API pointer path
        def to_jsonapi_pointer(attribute, prefix: '/data/attributes')
          parts = attribute.to_s.split('.')
          "#{prefix}/#{parts.join('/')}"
        end

        # Return the attribute path as-is (flat format).
        #
        # @param attribute [Symbol, String] The attribute path
        # @return [String] The attribute as a string
        def to_flat(attribute)
          attribute.to_s
        end
      end
    end
  end
end
