# frozen_string_literal: true
# typed: true

module EasyTalk
  module Builders
    # Base builder class for array-type properties.
    module CollectionHelpers
      extend T::Sig

      sig { returns(T::Boolean) }
      def collection_type?
        true
      end
    end
  end
end
