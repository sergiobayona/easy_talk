require_relative 'base_builder'

module EsquemaBase
  module Builders
    class NullBuilder < BaseBuilder
      VALID_OPTIONS = COMMON_OPTIONS.merge({})

      def initialize(name, options = {})
        options.assert_valid_keys(VALID_OPTIONS.keys)
        @name = name
        @options = options
        @valid_options = VALID_OPTIONS
        @schema = { type: 'null' }
      end
    end
  end
end
