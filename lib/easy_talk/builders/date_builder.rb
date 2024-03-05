require_relative 'base_builder'

module EasyTalk
  module Builders
    class DateBuilder < StringBuilder
      def schema
        super.tap do |schema|
          schema[:format] = 'date'
        end
      end
    end
  end
end
