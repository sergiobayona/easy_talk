module EasyTalk
  module Types
    class OneOf
      attr_reader :types

      def initialize(*args)
        @types = args
        insert_schema
      end

      def self.name
        'OneOf'
      end

      def name
        'OneOf'
      end

      def insert_schema
        binding.pry
        EasyTalk::CurrentContext.schema_definitions << self
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
