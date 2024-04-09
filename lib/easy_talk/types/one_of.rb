# frozen_string_literal: true

require_relative 'base_composer'
module EasyTalk
  module Types
    # Represents a composition type that allows one of the specified types.
    class OneOf < BaseComposer
      # Returns the name of the composition type.
      def self.name
        :oneOf
      end

      # Returns the name of the composition type.
      def name
        :oneOf
      end
    end
  end
end

module T
  # Creates a new instance of `EasyTalk::Types::OneOf` with the given arguments.
  #
  # @param args [Array] the list of arguments to be passed to the `EasyTalk::Types::OneOf` constructor
  # @return [EasyTalk::Types::OneOf] a new instance of `EasyTalk::Types::OneOf`
  module OneOf
    def self.[](*args)
      EasyTalk::Types::OneOf.new(*args)
    end
  end
end
