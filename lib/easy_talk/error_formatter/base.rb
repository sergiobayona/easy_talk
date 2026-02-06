# frozen_string_literal: true

module EasyTalk
  module ErrorFormatter
    # Abstract base class for error formatters.
    #
    # Provides common functionality for transforming ActiveModel::Errors
    # into standardized formats. Subclasses implement the `format` method
    # to produce specific output formats.
    #
    # @abstract Subclass and implement {#format} to create a formatter.
    #
    # @example Creating a custom formatter
    #   class CustomFormatter < EasyTalk::ErrorFormatter::Base
    #     def format
    #       error_entries.map do |entry|
    #         { custom_field: entry[:attribute], custom_message: entry[:message] }
    #       end
    #     end
    #   end
    #
    class Base
      attr_reader :errors, :options

      # Initialize a new formatter.
      #
      # @param errors [ActiveModel::Errors] The errors object to format
      # @param options [Hash] Formatting options
      # @option options [Boolean] :include_codes Whether to include error codes
      def initialize(errors, options = {})
        @errors = errors
        @options = options
      end

      # Format the errors into the target format.
      #
      # @abstract
      # @return [Hash, Array] The formatted errors
      # @raise [NotImplementedError] if the subclass does not implement this method
      def format
        raise NotImplementedError, "#{self.class} must implement #format"
      end

      protected

      # Check if error codes should be included in the output.
      #
      # @return [Boolean]
      def include_codes?
        @options.fetch(:include_codes, EasyTalk.configuration.include_error_codes)
      end

      # Build a normalized list of error entries from ActiveModel::Errors.
      #
      # Each entry contains:
      # - :attribute - The attribute name (may include dots for nested)
      # - :message - The error message
      # - :full_message - The full error message with attribute name
      # - :type - The error type from errors.details (e.g., :blank, :too_short)
      # - :detail_options - Additional options from the error detail
      #
      # @return [Array<Hash>] The normalized error entries
      def error_entries
        @error_entries ||= build_error_entries
      end

      private

      def build_error_entries
        # Group details by attribute for matching
        details_by_attr = {}
        errors.details.each do |attr, detail_list|
          details_by_attr[attr] = detail_list.dup
        end

        errors.map do |error|
          attr = error.attribute
          detail = find_and_consume_detail(details_by_attr, attr)

          {
            attribute: attr,
            message: error.message,
            full_message: error.full_message,
            type: detail[:error],
            detail_options: detail.except(:error)
          }
        end
      end

      # Find and consume a detail entry for an attribute.
      # This handles the case where an attribute has multiple errors.
      def find_and_consume_detail(details_by_attr, attribute)
        detail_list = details_by_attr[attribute]
        return {} if detail_list.blank?

        detail_list.shift || {}
      end
    end
  end
end
