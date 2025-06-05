# frozen_string_literal: true

require_relative 'base_composer'

module EasyTalk
  module Types
    # Base class for composition types
    class Composer < BaseComposer
      # Returns the name of the composition type.
      def self.name
        raise NotImplementedError, "#{self.class.name} must implement the name method"
      end

      # Returns the name of the composition type.
      def name
        self.class.name
      end

      # Represents a composition type that allows all of the specified types.
      class AllOf < Composer
        def self.name
          :allOf
        end

        def name
          :allOf
        end
      end

      # Represents a composition type that allows any of the specified types.
      class AnyOf < Composer
        def self.name
          :anyOf
        end

        def name
          :anyOf
        end
      end

      # Represents a composition type that allows one of the specified types.
      class OneOf < Composer
        def self.name
          :oneOf
        end

        def name
          :oneOf
        end
      end
    end
  end
end

# Shorthand module for accessing the AllOf composer
module T
  # Provides composition logic for combining multiple schemas with AllOf semantics
  module AllOf
    # Creates a new instance of `EasyTalk::Types::Composer::AllOf` with the given arguments.
    #
    # @param args [Array] the list of arguments to be passed to the constructor
    # @return [EasyTalk::Types::Composer::AllOf] a new instance
    def self.[](*args)
      EasyTalk::Types::Composer::AllOf.new(*args)
    end
  end

  # Shorthand module for accessing the AnyOf composer
  module AnyOf
    # Creates a new instance of `EasyTalk::Types::Composer::AnyOf` with the given arguments.
    #
    # @param args [Array] the list of arguments to be passed to the constructor
    # @return [EasyTalk::Types::Composer::AnyOf] a new instance
    def self.[](*args)
      EasyTalk::Types::Composer::AnyOf.new(*args)
    end
  end

  # Shorthand module for accessing the OneOf composer
  module OneOf
    # Creates a new instance of `EasyTalk::Types::Composer::OneOf` with the given arguments.
    #
    # @param args [Array] the list of arguments to be passed to the constructor
    # @return [EasyTalk::Types::Composer::OneOf] a new instance
    def self.[](*args)
      EasyTalk::Types::Composer::OneOf.new(*args)
    end
  end
end
