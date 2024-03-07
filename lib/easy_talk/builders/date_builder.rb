# frozen_string_literal: true

require_relative 'base_builder'

module EasyTalk
  module Builders
    class DateBuilder < StringBuilder
      # Modifies the schema to include the format constraint for a date property.
      sig { returns(T::Hash[Symbol, T.untyped]) }
      def schema
        super.tap do |schema|
          schema[:format] = 'date'
        end
      end
    end
  end
end
