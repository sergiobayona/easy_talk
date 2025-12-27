# frozen_string_literal: true

module EasyTalk
  module ErrorFormatter
    # Maps ActiveModel validation error types to semantic error codes.
    #
    # ActiveModel's `errors.details` provides the validation type (e.g., :blank, :too_short).
    # This class maps those types to standardized semantic codes for API responses.
    #
    # @example
    #   ErrorCodeMapper.map(:blank)        # => "blank"
    #   ErrorCodeMapper.map(:too_short)    # => "too_short"
    #   ErrorCodeMapper.map(:invalid)      # => "invalid_format"
    #
    class ErrorCodeMapper
      # Mapping of ActiveModel error types to semantic codes
      VALIDATION_TO_CODE = {
        # Presence validations
        blank: 'blank',
        present: 'present',
        empty: 'empty',

        # Format validations
        invalid: 'invalid_format',

        # Length validations
        too_short: 'too_short',
        too_long: 'too_long',
        wrong_length: 'wrong_length',

        # Numericality validations
        not_a_number: 'not_a_number',
        not_an_integer: 'not_an_integer',
        greater_than: 'too_small',
        greater_than_or_equal_to: 'too_small',
        less_than: 'too_large',
        less_than_or_equal_to: 'too_large',
        equal_to: 'not_equal',
        other_than: 'equal',
        odd: 'not_odd',
        even: 'not_even',

        # Inclusion/exclusion validations
        inclusion: 'not_included',
        exclusion: 'excluded',

        # Other validations
        taken: 'taken',
        confirmation: 'confirmation',
        accepted: 'not_accepted'
      }.freeze

      class << self
        # Map an ActiveModel error type to a semantic code.
        #
        # @param error_type [Symbol, String] The ActiveModel error type
        # @return [String] The semantic error code
        def map(error_type)
          VALIDATION_TO_CODE[error_type.to_sym] || error_type.to_s
        end

        # Extract the error code from an ActiveModel error detail hash.
        #
        # @param detail [Hash] The error detail from errors.details
        # @return [String] The semantic error code
        #
        # @example
        #   ErrorCodeMapper.code_from_detail({ error: :blank })
        #   # => "blank"
        #
        #   ErrorCodeMapper.code_from_detail({ error: :too_short, count: 2 })
        #   # => "too_short"
        def code_from_detail(detail)
          error_key = detail[:error]
          return 'unknown' unless error_key

          map(error_key)
        end
      end
    end
  end
end
