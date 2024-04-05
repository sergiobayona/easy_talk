require_relative 'base_composer'
module EasyTalk
  module Types
    class AllOf < BaseComposer
      def self.name
        :allOf
      end

      def name
        :allOf
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
