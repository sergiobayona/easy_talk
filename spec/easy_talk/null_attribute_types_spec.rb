# frozen_string_literal: true

require 'spec_helper'
require 'active_record'
require 'sqlite3'

RSpec.describe 'null vs optional' do
  context 'for PORO' do
    let(:address) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'User'
        end

        define_schema do
          property :name, String
          property :age, T.nilable(Integer)
          property :email, String, optional: true
        end
      end
    end

    it 'has age as type or null' do
      expect(address.json_schema['properties']['age']['type']).to eq(%w[integer null])
    end

    it 'includes age in the required array' do
      expect(address.json_schema['required']).to include('age')
    end

    it 'includes name in the required array' do
      expect(address.json_schema['required']).to include('name')
    end

    it 'does not include email in the required array' do
      expect(address.json_schema['required']).not_to include('email')
    end

    it 'returns a valid json schema' do
      expect(address.json_schema).to eq(
        {
          'type' => 'object',
          'properties' => {
            'name' => { 'type' => 'string' },
            'age' => { 'type' => %w[integer null] },
            'email' => { 'type' => 'string' }
          },
          'additionalProperties' => false,
          'required' => %w[name age]
        }
      )
    end
  end

  context 'for ActiveRecord' do
    before(:all) do
      # 1) Connect to an in-memory SQLite database
      ActiveRecord::Base.establish_connection(
        adapter: 'sqlite3',
        database: ':memory:'
      )

      # 2) Create a simple table to test with
      ActiveRecord::Schema.define do
        create_table :users, force: true do |t|
          t.string :name, null: false
          t.integer :age, null: true
          t.string :email, null: false
          t.timestamps
        end
      end
    end

    after(:all) do
      ActiveRecord::Schema.define do
        drop_table :users, if_exists: true
      end
    end

    let(:user) do
      Class.new(ActiveRecord::Base) do
        include EasyTalk::Model

        self.table_name = 'users'

        def self.name
          'User'
        end

        enhance_schema({
                         properties: {
                           email: { optional: true }
                         }
                       })
      end
    end

    it 'has an a nilable age column' do
      expect(user.columns.find { |c| c.name == 'age' }.null).to be(true)
    end

    it 'has age as type or null' do
      expect(user.json_schema['properties']['age']['type']).to eq(%w[integer null])
    end

    it 'includes age in the required array' do
      expect(user.json_schema['required']).to include('age')
    end

    it 'does not include email in the required array' do
      expect(user.json_schema['required']).not_to include('email')
    end

    it 'returns a valid json schema' do
      expect(user.json_schema).to eq(
        {
          'type' => 'object',
          'title' => 'User',
          'properties' => {
            'name' => { 'type' => 'string' },
            'age' => { 'type' => %w[integer null] },
            'email' => { 'type' => 'string' }
          },
          'additionalProperties' => false,
          'required' => %w[name age]
        }
      )
    end
  end
end
