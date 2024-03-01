require_relative 'base_builder'

module EsquemaBase
  module Builders
    class TimeBuilder < StringBuilder
      def schema
        super.tap do |schema|
          schema[:format] = 'time'
        end
      end
    end
  end
end
