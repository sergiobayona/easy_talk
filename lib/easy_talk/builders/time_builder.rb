# frozen_string_literal: true

require_relative 'base_builder'

module EasyTalk
  module Builders
    # Builder class for time properties.
    class TimeBuilder < StringBuilder
      def schema
        super.tap do |schema|
          schema[:format] = 'time'
        end
      end
    end
  end
end
