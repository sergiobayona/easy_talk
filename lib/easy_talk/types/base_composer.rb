# frozen_string_literal: true

module EasyTalk
  module Types
    # no-doc
    class BaseComposer
      extend T::Sig
      extend T::Generic

      Elem = type_member

      sig { returns(T::Array[Elem]) }
      attr_reader :items

      # Initializes a new instance of the BaseComposer class.
      #
      # @param args [Array] the items to be assigned to the instance variable @items
      def initialize(*args)
        @items = args
      end
    end
  end
end
