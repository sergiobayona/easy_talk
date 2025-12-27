# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::Builders::ObjectBuilder do
  describe 'schema immutability' do
    let(:model) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'TestModel'
        end

        define_schema do
          property :name, String, as: :full_name
          property :age, Integer
        end
      end
    end

    it 'does not mutate the original schema definition when building' do
      schema_definition = model.schema_definition
      original_constraints = schema_definition.schema[:properties][:name][:constraints].dup

      # Build the schema multiple times
      described_class.new(schema_definition).build
      described_class.new(schema_definition).build

      # The original constraints should remain unchanged
      expect(schema_definition.schema[:properties][:name][:constraints]).to eq(original_constraints)
    end

    it 'preserves the :as constraint in the original schema after building' do
      schema_definition = model.schema_definition

      # Build the schema
      described_class.new(schema_definition).build

      # The :as constraint should still be present
      expect(schema_definition.schema[:properties][:name][:constraints][:as]).to eq(:full_name)
    end

    it 'produces consistent JSON schema across multiple builds' do
      # Using model.json_schema calls the builder internally
      first_json = model.json_schema
      # Reset the cached schema to force rebuild
      model.instance_variable_set(:@schema, nil)
      model.instance_variable_set(:@json_schema, nil)
      second_json = model.json_schema

      expect(first_json).to eq(second_json)
    end
  end
end
