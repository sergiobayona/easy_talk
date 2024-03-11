# frozen_string_literal: true

# This module provides additional functionality for working with Sorbet types.
module SorbetExtension
  # Checks if the types in the collection include the NilClass type.
  #
  # @return [Boolean] true if the types include NilClass, false otherwise.
  def nilable?
    types.any? do |type|
      type.respond_to?(:raw_type) && type.raw_type == NilClass
    end
  end
end

T::Types::Union.include SorbetExtension
