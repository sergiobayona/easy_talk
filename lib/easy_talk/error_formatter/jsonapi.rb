# frozen_string_literal: true

module EasyTalk
  module ErrorFormatter
    # Formats validation errors according to the JSON:API specification.
    #
    # JSON:API defines a standard error format with specific fields for
    # status, source, title, detail, and optional code.
    #
    # @see https://jsonapi.org/format/#error-objects
    #
    # @example Output
    #   {
    #     "errors" => [
    #       {
    #         "status" => "422",
    #         "code" => "blank",
    #         "source" => { "pointer" => "/data/attributes/name" },
    #         "title" => "Invalid Attribute",
    #         "detail" => "Name can't be blank"
    #       }
    #     ]
    #   }
    #
    class Jsonapi < Base
      # Default values for JSON:API error fields
      DEFAULT_STATUS = '422'
      DEFAULT_TITLE = 'Invalid Attribute'

      # Format the errors as a JSON:API error response.
      #
      # @return [Hash] The JSON:API error object with "errors" array
      def format
        {
          'errors' => build_errors_array
        }
      end

      private

      def build_errors_array
        error_entries.map do |entry|
          build_error_object(entry)
        end
      end

      def build_error_object(entry)
        error = {
          'status' => options.fetch(:status, DEFAULT_STATUS).to_s,
          'source' => {
            'pointer' => PathConverter.to_jsonapi_pointer(
              entry[:attribute],
              prefix: options.fetch(:source_prefix, '/data/attributes')
            )
          },
          'title' => options.fetch(:title, DEFAULT_TITLE),
          'detail' => entry[:full_message]
        }
        error['code'] = ErrorCodeMapper.map(entry[:type]) if include_codes? && entry[:type]
        error
      end
    end
  end
end
