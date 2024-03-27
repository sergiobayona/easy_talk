# frozen_string_literal: true

require_relative 'base_builder'

module EasyTalk
  module Builders
    # Builder class for array properties.
    class RefArrayBuilder < BaseBuilder
      # Initializes a new instance of the ArrayBuilder class.
      sig { params(name: Symbol).void }
      def initialize(name)
        super(name, { type: 'array' }, options, {})
      end

      private

      sig { void }
      # Updates the option types for the array builder.
      def update_option_types
        VALID_OPTIONS[:enum][:type] = T::Array[@inner_type]
        VALID_OPTIONS[:const][:type] = T::Array[@inner_type]
      end
    end
  end
end
