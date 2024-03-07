# frozen_string_literal: true

require_relative 'base_builder'

module EasyTalk
  module Builders
    # Builder class for datetime properties.
    class DatetimeBuilder < StringBuilder
      # Modifies the schema to include the format constraint for a datetime property.
      sig { returns(T::Hash[Symbol, T.untyped]) }
      def schema
        super.tap do |schema|
          schema[:format] = 'date-time'
        end
      end
    end
  end
end
