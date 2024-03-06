# frozen_string_literal: true

require_relative 'base_builder'

module EasyTalk
  module Builders
    class DatetimeBuilder < StringBuilder
      def schema
        super.tap do |schema|
          schema[:format] = 'date-time'
        end
      end
    end
  end
end
