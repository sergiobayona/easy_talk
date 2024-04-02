require_relative 'compositional_keyword'
module EasyTalk
  module Types
    class AnyOf
      attr_reader :types

      def initialize(*args)
        @types = args
      end

      def self.name
        'AnyOf'
      end

      def name
        'AnyOf'
      end
    end
  end
end

module T
  module AnyOf
    def self.[](*args)
      EasyTalk::Types::AnyOf.new(*args)
    end
  end
end
