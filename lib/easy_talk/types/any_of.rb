require_relative 'base_composer'
module EasyTalk
  module Types
    class AnyOf < BaseComposer
      def self.name
        :anyOf
      end

      def name
        :anyOf
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
