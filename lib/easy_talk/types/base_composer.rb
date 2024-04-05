module EasyTalk
  module Types
    class BaseComposer
      extend T::Sig
      extend T::Generic

      Elem = type_member

      sig { returns(T::Array[Elem]) }
      attr_reader :items

      def initialize(*args)
        @items = args
      end
    end
  end
end
