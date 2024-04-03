module EasyTalk
  module Types
    class AllOf
      attr_reader :types

      def initialize(*args)
        @types = args
      end

      def self.name
        'AllOf'
      end

      def name
        'AllOf'
      end
    end
  end
end

module T
  module AllOf
    def self.[](*args)
      EasyTalk::Types::AllOf.new(*args)
    end
  end
end
