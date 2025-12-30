# frozen_string_literal: true
# typed: true

require_relative 'string_builder'

module EasyTalk
  module Builders
    # Builder class for temporal properties (date, datetime, time).
    class TemporalBuilder < StringBuilder
      extend T::Sig

      # Initializes a new instance of the TemporalBuilder class.
      #
      # @param property_name [Symbol] The name of the property.
      # @param options [Hash] The options for the builder.
      # @param format [String] The format of the temporal property (date, date-time, time).
      sig { params(property_name: Symbol, options: T::Hash[Symbol, T.untyped], format: T.nilable(String)).void }
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
        sig { params(property_name: Symbol, options: T::Hash[Symbol, T.untyped]).void }
        def initialize(property_name, options = {})
          super(property_name, options, 'date')
        end
      end

      # Builder class for datetime properties.
      class DatetimeBuilder < TemporalBuilder
        sig { params(property_name: Symbol, options: T::Hash[Symbol, T.untyped]).void }
        def initialize(property_name, options = {})
          super(property_name, options, 'date-time')
        end
      end

      # Builder class for time properties.
      class TimeBuilder < TemporalBuilder
        sig { params(property_name: Symbol, options: T::Hash[Symbol, T.untyped]).void }
        def initialize(property_name, options = {})
          super(property_name, options, 'time')
        end
      end
    end
  end
end
