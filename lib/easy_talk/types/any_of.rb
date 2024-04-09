# frozen_string_literal: true

require_relative 'base_composer'
module EasyTalk
  module Types
    # The `Types` module provides a collection of composers for defining different types.
    #
    # This module contains composers for various types such as `AnyOf`, `AllOf`, etc.
    # Each composer is responsible for defining the behavior and properties of its respective type.
    class AnyOf < BaseComposer
      # Returns the name of the AnyOf composer.
      #
      # @return [Symbol] The name of the composer.
      def self.name
        :anyOf
      end

      # Returns the name of the AnyOf composer.
      #
      # @return [Symbol] The name of the composer.
      def name
        :anyOf
      end
    end
  end
end

module T
  # no-doc
  module AnyOf
    # Creates a new instance of `EasyTalk::Types::AnyOf` with the given arguments.
    #
    # @param args [Array] the list of arguments to be passed to the `EasyTalk::Types::AnyOf` constructor
    # @return [EasyTalk::Types::AnyOf] a new instance of `EasyTalk::Types::AnyOf`
    def self.[](*args)
      EasyTalk::Types::AnyOf.new(*args)
    end
  end
end
