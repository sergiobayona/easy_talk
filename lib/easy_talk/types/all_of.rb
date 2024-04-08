# frozen_string_literal: true

require_relative 'base_composer'
# The EasyTalk module provides a collection of types for composing schemas.
module EasyTalk
  # The `Types` module provides a collection of classes for composing different types.
  module Types
    # Represents a composition type that allows all of the specified types.
    class AllOf < BaseComposer
      def self.name
        :allOf
      end

      def name
        :allOf
      end
    end
  end
end

module T
  # no-doc
  module AllOf
    # Creates a new instance of `EasyTalk::Types::AllOf` with the given arguments.
    #
    # @param args [Array] the list of arguments to be passed to the `EasyTalk::Types::AllOf` constructor
    # @return [EasyTalk::Types::AllOf] a new instance of `EasyTalk::Types::AllOf`
    def self.[](*args)
      EasyTalk::Types::AllOf.new(*args)
    end
  end
end
