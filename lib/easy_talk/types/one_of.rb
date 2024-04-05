require_relative 'base_composer'
module EasyTalk
  module Types
    class OneOf < BaseComposer
      def self.name
        :oneOf
      end

      def name
        :oneOf
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
