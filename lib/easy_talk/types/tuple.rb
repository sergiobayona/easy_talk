# frozen_string_literal: true

module EasyTalk
  module Types
    # Represents a tuple type for arrays with positional type validation.
    #
    # A tuple is an array where each position has a specific type. This class
    # stores the types for each position.
    #
    # @example Basic tuple
    #   T::Tuple[String, Integer]  # First item must be String, second must be Integer
    #
    # @example With additional_items constraint
    #   property :flags, T::Tuple[T::Boolean, T::Boolean], additional_items: false
    #
    class Tuple
      extend T::Sig

      # @return [Array<Object>] The types for each position in the tuple
      sig { returns(T::Array[T.untyped]) }
      attr_reader :types

      # Creates a new Tuple instance with the given positional types.
      #
      # @param types [Array] The types for each position in the tuple
      # @raise [ArgumentError] if types is empty or contains nil values
      sig { params(types: T.untyped).void }
      def initialize(*types)
        raise ArgumentError, 'Tuple requires at least one type' if types.empty?
        raise ArgumentError, 'Tuple types cannot be nil' if types.any?(&:nil?)

        @types = types.freeze
      end

      # Returns a string representation of the tuple type.
      #
      # @return [String] A human-readable representation
      sig { returns(String) }
      def to_s
        type_names = @types.map { |t| (t.respond_to?(:name) && t.name) || t.to_s }
        "T::Tuple[#{type_names.join(', ')}]"
      end

      # Returns the name of this type (used by Property for error messages).
      #
      # @return [String] The type name
      sig { returns(String) }
      def name
        to_s
      end
    end
  end
end

# Add T::Tuple module for bracket syntax
module T
  # Provides tuple type syntax: T::Tuple[Type1, Type2, ...]
  #
  # Creates a tuple type that validates array elements by position.
  #
  # @example Basic usage
  #   property :coordinates, T::Tuple[Float, Float]
  #   property :record, T::Tuple[String, Integer, T::Boolean]
  #
  # @example With additional_items constraint
  #   property :flags, T::Tuple[T::Boolean, T::Boolean], additional_items: false
  #
  module Tuple
    # Creates a new Tuple type with the given positional types.
    #
    # @param types [Array] The types for each position
    # @return [EasyTalk::Types::Tuple] A new Tuple instance
    def self.[](*types)
      EasyTalk::Types::Tuple.new(*types)
    end
  end
end
