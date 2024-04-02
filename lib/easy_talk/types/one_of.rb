require_relative 'compositional_keyword'
module EasyTalk
  module Types
    class OneOf
      attr_reader :types

      def initialize(*args)
        @types = args
      end

      def self.name
        'OneOf'
      end

      def name
        'OneOf'
      end
    end
  end
end

module T
  module OneOf
    def self.[](*args)
      EasyTalk::Types::OneOf.new(*args)
    end
  end
end
