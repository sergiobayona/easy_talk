# frozen_string_literal: true

module EasyTalk
  module ErrorFormatter
    # Formats validation errors as a simple flat array.
    #
    # This is the simplest format, providing an array of error objects
    # with field name, message, and optional error code.
    #
    # @example Output
    #   [
    #     { "field" => "name", "message" => "can't be blank", "code" => "blank" },
    #     { "field" => "email.address", "message" => "is invalid", "code" => "invalid_format" }
    #   ]
    #
    class Flat < Base
      # Format the errors as a flat array.
      #
      # @return [Array<Hash>] Array of error objects
      def format
        error_entries.map do |entry|
          build_error_object(entry)
        end
      end

      private

      def build_error_object(entry)
        error = {
          'field' => PathConverter.to_flat(entry[:attribute]),
          'message' => entry[:message]
        }
        error['code'] = ErrorCodeMapper.map(entry[:type]) if include_codes? && entry[:type]
        error
      end
    end
  end
end
