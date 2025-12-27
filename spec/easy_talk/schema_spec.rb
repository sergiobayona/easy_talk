# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::Schema do
  describe 'basic functionality' do
    let(:schema_class) do
      Class.new do
        include EasyTalk::Schema
        def self.name = 'ApiContract'

        define_schema do
          title 'API Contract'
          description 'A schema-only contract'
          property :name, String
          property :age, Integer, minimum: 0
        end
      end
    end

    it 'generates JSON schema' do
      schema = schema_class.json_schema

      expect(schema['type']).to eq('object')
      expect(schema['title']).to eq('API Contract')
      expect(schema['description']).to eq('A schema-only contract')
      expect(schema['properties']['name']['type']).to eq('string')
      expect(schema['properties']['age']['type']).to eq('integer')
      expect(schema['properties']['age']['minimum']).to eq(0)
    end

    it 'does not include ActiveModel::Validations' do
      expect(schema_class.ancestors).not_to include(ActiveModel::Validations)
    end

    it 'does not respond to valid?' do
      instance = schema_class.new(name: 'Test', age: 25)
      expect(instance).not_to respond_to(:valid?)
    end

    it 'does not respond to errors' do
      instance = schema_class.new(name: 'Test', age: 25)
      expect(instance).not_to respond_to(:errors)
    end

    it 'initializes with attributes' do
      instance = schema_class.new(name: 'Test', age: 25)
      expect(instance.name).to eq('Test')
      expect(instance.age).to eq(25)
    end

    it 'accepts string keys in attributes' do
      instance = schema_class.new('name' => 'Test', 'age' => 25)
      expect(instance.name).to eq('Test')
      expect(instance.age).to eq(25)
    end
  end

  describe '#to_hash' do
    let(:schema_class) do
      Class.new do
        include EasyTalk::Schema
        def self.name = 'HashTest'

        define_schema do
          property :name, String
          property :count, Integer
        end
      end
    end

    it 'converts to hash' do
      instance = schema_class.new(name: 'Test', count: 5)
      expect(instance.to_hash).to eq({ 'name' => 'Test', 'count' => 5 })
    end
  end

  describe '#as_json' do
    let(:schema_class) do
      Class.new do
        include EasyTalk::Schema
        def self.name = 'JsonTest'

        define_schema do
          property :name, String
        end
      end
    end

    it 'returns JSON-compatible hash' do
      instance = schema_class.new(name: 'Test')
      expect(instance.as_json).to eq({ 'name' => 'Test' })
    end
  end

  describe 'default values' do
    let(:schema_class) do
      Class.new do
        include EasyTalk::Schema
        def self.name = 'DefaultTest'

        define_schema do
          property :status, String, default: 'active'
          property :count, Integer, default: 0
        end
      end
    end

    it 'applies default values when not provided' do
      instance = schema_class.new({})
      expect(instance.status).to eq('active')
      expect(instance.count).to eq(0)
    end

    it 'does not override provided values with defaults' do
      instance = schema_class.new(status: 'inactive', count: 5)
      expect(instance.status).to eq('inactive')
      expect(instance.count).to eq(5)
    end
  end

  describe 'nested schemas' do
    let(:address_class) do
      Class.new do
        include EasyTalk::Schema
        def self.name = 'Address'

        define_schema do
          property :street, String
          property :city, String
        end
      end
    end

    let(:person_class) do
      address = address_class
      Class.new do
        include EasyTalk::Schema
        define_singleton_method(:name) { 'Person' }

        define_schema do
          property :name, String
          property :address, address
        end
      end
    end

    it 'auto-instantiates nested schema objects from hashes' do
      person = person_class.new(
        name: 'John',
        address: { street: '123 Main St', city: 'Boston' }
      )

      expect(person.address).to be_a(address_class)
      expect(person.address.street).to eq('123 Main St')
      expect(person.address.city).to eq('Boston')
    end
  end

  describe '.properties' do
    let(:schema_class) do
      Class.new do
        include EasyTalk::Schema
        def self.name = 'PropertiesTest'

        define_schema do
          property :name, String
          property :age, Integer
        end
      end
    end

    it 'returns property names' do
      expect(schema_class.properties).to eq(%i[name age])
    end
  end

  describe '.ref_template' do
    let(:schema_class) do
      Class.new do
        include EasyTalk::Schema
        def self.name = 'RefTest'

        define_schema do
          property :name, String
        end
      end
    end

    it 'returns the reference template' do
      expect(schema_class.ref_template).to eq('#/$defs/RefTest')
    end
  end

  describe 'comparison with hashes' do
    let(:schema_class) do
      Class.new do
        include EasyTalk::Schema
        def self.name = 'CompareTest'

        define_schema do
          property :name, String
          property :age, Integer
        end
      end
    end

    it 'can be compared to hashes' do
      instance = schema_class.new(name: 'Test', age: 25)

      expect(instance == { name: 'Test', age: 25 }).to be true
      expect(instance == { name: 'Different', age: 25 }).to be false
    end
  end
end
