# frozen_string_literal: true

require_relative 'error_formatter/error_code_mapper'
require_relative 'error_formatter/path_converter'
require_relative 'error_formatter/base'
require_relative 'error_formatter/flat'
require_relative 'error_formatter/json_pointer'
require_relative 'error_formatter/rfc7807'
require_relative 'error_formatter/jsonapi'

module EasyTalk
  # Module for formatting ActiveModel validation errors into standardized formats.
  #
  # Provides multiple output formats for API responses:
  # - `:flat` - Simple flat array of field/message/code objects
  # - `:json_pointer` - Array with JSON Pointer (RFC 6901) paths
  # - `:rfc7807` - RFC 7807 Problem Details format
  # - `:jsonapi` - JSON:API specification error format
  #
  # @example Using via model instance methods
  #   user = User.new(name: '')
  #   user.valid?
  #
  #   user.validation_errors                    # Uses default format from config
  #   user.validation_errors_flat               # Flat format
  #   user.validation_errors_json_pointer       # JSON Pointer format
  #   user.validation_errors_rfc7807            # RFC 7807 format
  #   user.validation_errors_jsonapi            # JSON:API format
  #
  # @example Using the format method directly
  #   EasyTalk::ErrorFormatter.format(user.errors, format: :rfc7807, title: 'Custom Title')
  #
  module ErrorFormatter
    # Map of format symbols to formatter classes
    FORMATTERS = {
      flat: Flat,
      json_pointer: JsonPointer,
      rfc7807: Rfc7807,
      jsonapi: Jsonapi
    }.freeze

    class << self
      # Format validation errors using the specified format.
      #
      # @param errors [ActiveModel::Errors] The errors object to format
      # @param format [Symbol] The output format (:flat, :json_pointer, :rfc7807, :jsonapi)
      # @param options [Hash] Format-specific options
      # @return [Hash, Array] The formatted errors
      # @raise [ArgumentError] If the format is not recognized
      #
      # @example
      #   EasyTalk::ErrorFormatter.format(user.errors, format: :flat)
      #   EasyTalk::ErrorFormatter.format(user.errors, format: :rfc7807, title: 'Validation Error')
      def format(errors, format: nil, **options)
        format ||= EasyTalk.configuration.default_error_format
        formatter_class = FORMATTERS[format.to_sym]

        raise ArgumentError, "Unknown error format: #{format}. Valid formats: #{FORMATTERS.keys.join(', ')}" unless formatter_class

        formatter_class.new(errors, options).format
      end
    end

    # Instance methods mixed into EasyTalk::Model classes.
    #
    # Provides convenient methods for formatting validation errors
    # on model instances.
    module InstanceMethods
      # Format validation errors using the default or specified format.
      #
      # @param format [Symbol] The output format (optional, uses config default)
      # @param options [Hash] Format-specific options
      # @return [Hash, Array] The formatted errors
      #
      # @example
      #   user.validation_errors
      #   user.validation_errors(format: :rfc7807, title: 'User Error')
      def validation_errors(format: nil, **)
        ErrorFormatter.format(errors, format: format, **)
      end

      # Format validation errors as a flat array.
      #
      # @param options [Hash] Format options
      # @option options [Boolean] :include_codes Whether to include error codes
      # @return [Array<Hash>] Array of error objects
      #
      # @example
      #   user.validation_errors_flat
      #   # => [{ "field" => "name", "message" => "can't be blank", "code" => "blank" }]
      def validation_errors_flat(**)
        ErrorFormatter.format(errors, format: :flat, **)
      end

      # Format validation errors with JSON Pointer paths.
      #
      # @param options [Hash] Format options
      # @option options [Boolean] :include_codes Whether to include error codes
      # @return [Array<Hash>] Array of error objects with pointer paths
      #
      # @example
      #   user.validation_errors_json_pointer
      #   # => [{ "pointer" => "/properties/name", "message" => "can't be blank", "code" => "blank" }]
      def validation_errors_json_pointer(**)
        ErrorFormatter.format(errors, format: :json_pointer, **)
      end

      # Format validation errors as RFC 7807 Problem Details.
      #
      # @param options [Hash] Format options
      # @option options [String] :title The problem title
      # @option options [Integer] :status The HTTP status code
      # @option options [String] :detail The problem detail message
      # @option options [String] :type_base_uri Base URI for error type
      # @option options [String] :type The error type suffix
      # @option options [Boolean] :include_codes Whether to include error codes
      # @return [Hash] The Problem Details object
      #
      # @example
      #   user.validation_errors_rfc7807
      #   user.validation_errors_rfc7807(title: 'User Validation Failed', status: 400)
      def validation_errors_rfc7807(**)
        ErrorFormatter.format(errors, format: :rfc7807, **)
      end

      # Format validation errors according to JSON:API specification.
      #
      # @param options [Hash] Format options
      # @option options [String] :status The HTTP status code (as string)
      # @option options [String] :title The error title
      # @option options [String] :source_prefix The source pointer prefix
      # @option options [Boolean] :include_codes Whether to include error codes
      # @return [Hash] The JSON:API error object
      #
      # @example
      #   user.validation_errors_jsonapi
      #   user.validation_errors_jsonapi(title: 'Validation Error', source_prefix: '/data')
      def validation_errors_jsonapi(**)
        ErrorFormatter.format(errors, format: :jsonapi, **)
      end
    end
  end
end
