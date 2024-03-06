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
  module Model
    extend ActiveSupport::Concern

    included do
      def self.schema
        @schema ||= {}
      end

      def self.json_schema
        @json_schema ||= schema.to_json
      end

      # Define the schema using the provided block.
      def self.define_schema(&block)
        schema_definition
        definition = SchemaDefinition.new(self, @schema_definition)
        definition.instance_eval(&block)
        @schema = Builder.new(definition).schema
      end

      # Returns the schema definition.
      # The schema_definition is a hash that contains the unvalidated schema definition for the model.
      # It is then passed to the Builder.build_schema method to validate and compile the schema.
      def self.schema_definition
        @schema_definition ||= {}
      end
    end
  end
end
