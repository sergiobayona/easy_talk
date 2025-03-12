# frozen_string_literal: true

require_relative 'string_builder'

module EasyTalk
  module Builders
    # Builder class for temporal properties (date, datetime, time).
    class TemporalBuilder < StringBuilder
      # Initializes a new instance of the TemporalBuilder class.
      #
      # @param property_name [Symbol] The name of the property.
      # @param options [Hash] The options for the builder.
      # @param format [String] The format of the temporal property (date, date-time, time).
      def initialize(property_name, options = {}, format = nil)
        super(property_name, options)
        @format = format
      end

      # Modifies the schema to include the format constraint for a temporal property.
      sig { returns(T::Hash[Symbol, T.untyped]) }
      def schema
        super.tap do |schema|
          schema[:format] = @format if @format
        end
      end

      # Builder class for date properties.
      class DateBuilder < TemporalBuilder
        def initialize(property_name, options = {})
          super(property_name, options, 'date')
        end
      end

      # Builder class for datetime properties.
      class DatetimeBuilder < TemporalBuilder
        def initialize(property_name, options = {})
          super(property_name, options, 'date-time')
        end
      end

      # Builder class for time properties.
      class TimeBuilder < TemporalBuilder
        def initialize(property_name, options = {})
          super(property_name, options, 'time')
        end
      end
    end
  end
end
