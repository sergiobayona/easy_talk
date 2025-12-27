# frozen_string_literal: true

module EasyTalk
  module ErrorFormatter
    # Formats validation errors according to RFC 7807 (Problem Details for HTTP APIs).
    #
    # RFC 7807 defines a standard format for describing errors in HTTP APIs.
    # This formatter produces a Problem Details object with validation errors
    # in an extended "errors" array.
    #
    # @see https://tools.ietf.org/html/rfc7807
    #
    # @example Output
    #   {
    #     "type" => "https://example.com/validation-error",
    #     "title" => "Validation Failed",
    #     "status" => 422,
    #     "detail" => "The request contains invalid parameters",
    #     "errors" => [
    #       { "pointer" => "/properties/name", "detail" => "can't be blank", "code" => "blank" }
    #     ]
    #   }
    #
    class Rfc7807 < Base
      # Default values for RFC 7807 fields
      DEFAULT_TITLE = 'Validation Failed'
      DEFAULT_STATUS = 422
      DEFAULT_DETAIL = 'The request contains invalid parameters'

      # Format the errors as an RFC 7807 Problem Details object.
      #
      # @return [Hash] The Problem Details object
      def format
        {
          'type' => error_type_uri,
          'title' => options.fetch(:title, DEFAULT_TITLE),
          'status' => options.fetch(:status, DEFAULT_STATUS),
          'detail' => options.fetch(:detail, DEFAULT_DETAIL),
          'errors' => build_errors_array
        }
      end

      private

      def error_type_uri
        base_uri = options.fetch(:type_base_uri, EasyTalk.configuration.error_type_base_uri)
        type_suffix = options.fetch(:type, 'validation-error')
        return type_suffix if base_uri.nil? || base_uri == 'about:blank'

        "#{base_uri.chomp('/')}/#{type_suffix}"
      end

      def build_errors_array
        error_entries.map do |entry|
          build_error_object(entry)
        end
      end

      def build_error_object(entry)
        error = {
          'pointer' => PathConverter.to_json_pointer(entry[:attribute]),
          'detail' => entry[:message]
        }
        error['code'] = ErrorCodeMapper.map(entry[:type]) if include_codes? && entry[:type]
        error
      end
    end
  end
end
