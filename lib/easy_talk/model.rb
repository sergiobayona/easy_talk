# frozen_string_literal: true

require 'json'
require 'active_support'
require 'active_support/core_ext'
require 'active_support/time'
require 'active_support/concern'
require 'active_support/json'
require_relative 'builder'
require_relative 'schema_definition'

module EasyTalk
  # The Model module can be included in a class to add JSON schema definition and generation support.
  module Model
    def self.included(base)
      base.extend(ClassMethods)

      base.singleton_class.instance_eval do
        define_method(:inherited) do |subclass|
          super(subclass)
          subclass.extend(SubclassExtension)
        end
      end
    end

    module SubclassExtension
      def inherits_schema?
        true
      end

      def inherits_from
        superclass
      end
    end

    module ClassMethods
      def schema
        @schema ||= {}
      end

      def inherits_schema?
        false
      end

      def ref_template
        "#/$defs/#{name}"
      end

      # Returns the JSON schema for the model.
      def json_schema
        @json_schema ||= schema.to_json
      end

      # Define the schema using the provided block.
      def define_schema(&block)
        raise ArgumentError, 'The class must have a name' unless name.present?

        schema_definition
        definition = SchemaDefinition.new(self, @schema_definition)
        definition.instance_eval(&block)
        @schema = Builder.new(definition).schema
      end

      # Returns the schema definition.
      # The schema_definition is a hash that contains the unvalidated schema definition for the model.
      # It is then passed to the Builder.build_schema method to validate and compile the schema.
      def schema_definition
        @schema_definition ||= {}
      end
    end
  end
end
