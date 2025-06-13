# frozen_string_literal: true

require 'spec_helper'
require 'active_record'
require 'sqlite3'

RSpec.describe 'EasyTalk::Model integration with ActiveRecord' do
  before(:all) do
    # 1) Connect to an in-memory SQLite database
    ActiveRecord::Base.establish_connection(
      adapter: 'sqlite3',
      database: ':memory:'
    )

    # 2) Create a simple table to test with
    ActiveRecord::Schema.define do
      create_table :companies, force: true do |t|
        t.string :name, null: false
        t.string :address, null: true
        t.integer :employee_count
        t.datetime :founded_at
        t.boolean :active, default: true
        t.boolean :profile_completed, default: false
        t.timestamps
      end
    end

    # 3) Define a minimal Company model that includes your ActiveRecordModel mixin
    class Company < ActiveRecord::Base
      include EasyTalk::Model

      # If you like, you can immediately call enhance_schema here, or do so in the tests
      enhance_schema({
                       title: 'Company',
                       description: 'A minimal example of an ActiveRecord model using EasyTalk'
                     })
    end
  end

  after(:all) do
    # Cleanup: drop the table if desired
    ActiveRecord::Schema.define do
      drop_table :companies, if_exists: true
    end
  end

  describe 'auto-generated schema' do
    it 'creates a base schema from the table columns' do
      # We expect it to define properties for :id, :name, :employee_count, :founded_at, etc.
      schema = Company.json_schema

      expect(schema['type']).to eq('object')
      expect(schema['title']).to eq('Company')
      expect(schema['description']).to eq('A minimal example of an ActiveRecord model using EasyTalk')

      # Check some of the auto-generated columns
      expect(schema['properties'].keys).to include('name', 'employee_count', 'founded_at', 'active', 'profile_completed')

      # name is non-null in the DB, so maybe you consider it "required" in your logic
      # that depends on how you interpreted NOT NULL => required
      # For now, let's just confirm that the property is recognized
      expect(schema['properties']['name']['type']).to eq('string')
    end
  end

  describe '#enhance_schema' do
    it 'allows further customization of the schema' do
      Company.enhance_schema(properties: { employee_count: { description: 'Number of employees' } })

      schema = Company.json_schema
      expect(schema['properties']['employee_count']['description']).to eq('Number of employees')
    end
  end

  describe 'required properties' do
    it 'includes required properties' do
      schema = Company.json_schema

      # all fields are required unless optional is true
      expect(schema['required']).to include('name')
      expect(schema['required']).to include('address')
      expect(schema['required']).to include('employee_count')
      expect(schema['required']).to include('founded_at')
    end

    context 'when enhancing the schema' do
      it 'includes required properties' do
        Company.enhance_schema(properties: { address: { optional: true } })
        schema = Company.json_schema
        expect(schema['required']).not_to include('address')
      end
    end
  end

  describe 'ActiveRecord usage' do
    it 'persists and loads data normally' do
      # Basic AR test to confirm everything still works
      company = Company.create!(name: 'TestCo', employee_count: 42)
      expect(company.id).not_to be_nil

      found = Company.find(company.id)
      expect(found.name).to eq('TestCo')
    end
  end

  describe 'schema generation with additionalProperties' do
    it 'includes additionalProperties: false by default' do
      schema = Company.json_schema
      expect(schema).to include('additionalProperties' => false)
    end

    it 'allows overriding the additionalProperties setting' do
      Company.enhance_schema(additionalProperties: true)
      schema = Company.json_schema
      expect(schema).to include('additionalProperties' => true)
    end
  end
end
