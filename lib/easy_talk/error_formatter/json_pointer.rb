# frozen_string_literal: true

module EasyTalk
  module ErrorFormatter
    # Formats validation errors using JSON Pointer (RFC 6901) paths.
    #
    # Converts attribute paths to JSON Pointer format pointing to the
    # property location in the JSON Schema.
    #
    # @example Output
    #   [
    #     { "pointer" => "/properties/name", "message" => "can't be blank", "code" => "blank" },
    #     { "pointer" => "/properties/email/properties/address", "message" => "is invalid", "code" => "invalid_format" }
    #   ]
    #
    class JsonPointer < Base
      # Format the errors as an array with JSON Pointer paths.
      #
      # @return [Array<Hash>] Array of error objects with pointer paths
      def format
        error_entries.map do |entry|
          build_error_object(entry)
        end
      end

      private

      def build_error_object(entry)
        error = {
          'pointer' => PathConverter.to_json_pointer(entry[:attribute]),
          'message' => entry[:message]
        }
        error['code'] = ErrorCodeMapper.map(entry[:type]) if include_codes? && entry[:type]
        error
      end
    end
  end
end
