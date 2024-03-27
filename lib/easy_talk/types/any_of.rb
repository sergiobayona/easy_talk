require_relative 'compositional_keyword'
module EasyTalk
  module Types
    include CompositionalKeyword
    class AnyOf
      def initialize(*args)
        @types = args
        insert_schemas
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
