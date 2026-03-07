# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'EasyTalk::Schema shared behavior from SchemaBase' do
  describe 'define_schema called twice clears stale state' do
    let(:schema_class) do
      Class.new do
        include EasyTalk::Schema

        def self.name = 'DynamicSchema'
      end
    end

    it 'returns the schema from the most recent define_schema call' do
      schema_class.define_schema do
        property :first_name, String
      end

      schema_class.define_schema do
        property :email, String
      end

      schema = schema_class.json_schema
      props = schema['properties']

      expect(props).to have_key('email')
      expect(props).not_to have_key('first_name')
    end

    it 'clears memoized json_schema on redefine' do
      schema_class.define_schema do
        property :a, String
      end

      first_schema = schema_class.json_schema

      schema_class.define_schema do
        property :b, Integer
      end

      second_schema = schema_class.json_schema

      expect(first_schema['properties']).to have_key('a')
      expect(second_schema['properties']).to have_key('b')
      expect(second_schema['properties']).not_to have_key('a')
    end
  end

  describe 'additional properties runtime behavior' do
    let(:schema_class) do
      Class.new do
        include EasyTalk::Schema

        def self.name = 'FlexibleSchema'

        define_schema do
          additional_properties true
          property :name, String
        end
      end
    end

    it 'allows setting additional properties via method calls' do
      instance = schema_class.new(name: 'Test')
      instance.extra_field = 'hello'

      expect(instance.extra_field).to eq('hello')
    end

    it 'includes additional properties in as_json' do
      instance = schema_class.new(name: 'Test')
      instance.extra_field = 'hello'

      json = instance.as_json
      expect(json).to include('name' => 'Test', 'extra_field' => 'hello')
    end

    it 'includes additional properties in to_h' do
      instance = schema_class.new(name: 'Test')
      instance.extra_field = 'hello'

      expect(instance.to_h).to include('name' => 'Test', 'extra_field' => 'hello')
    end

    it 'responds to additional property getters and setters' do
      instance = schema_class.new(name: 'Test')
      instance.extra_field = 'hello'

      expect(instance.respond_to?(:extra_field)).to be true
      expect(instance.respond_to?(:extra_field=)).to be true
    end

    it 'accepts additional properties during initialization' do
      instance = schema_class.new(name: 'Test', extra_field: 'hello', another: 42)

      expect(instance.name).to eq('Test')
      expect(instance.extra_field).to eq('hello')
      expect(instance.another).to eq(42)
      expect(instance.as_json).to include('extra_field' => 'hello', 'another' => 42)
    end

    it 'raises NoMethodError for unknown properties when additional_properties is false' do
      strict_class = Class.new do
        include EasyTalk::Schema

        def self.name = 'StrictSchema'

        define_schema do
          property :name, String
        end
      end

      instance = strict_class.new(name: 'Test')
      expect { instance.unknown_prop }.to raise_error(NoMethodError)
    end
  end

  describe 'T::Array nested model instantiation' do
    let(:item_class) do
      Class.new do
        include EasyTalk::Schema

        def self.name = 'LineItem'

        define_schema do
          property :product, String
          property :qty, Integer
        end
      end
    end

    let(:order_class) do
      item = item_class
      Class.new do
        include EasyTalk::Schema

        define_singleton_method(:name) { 'Order' }

        define_schema do
          property :id, Integer
          property :items, T::Array[item]
        end
      end
    end

    it 'auto-instantiates array items from hashes' do
      order = order_class.new(
        id: 1,
        items: [
          { product: 'Widget', qty: 3 },
          { product: 'Gadget', qty: 1 }
        ]
      )

      expect(order.items).to all(be_a(item_class))
      expect(order.items[0].product).to eq('Widget')
      expect(order.items[1].qty).to eq(1)
    end

    it 'preserves already-instantiated items' do
      existing = item_class.new(product: 'Existing', qty: 5)
      order = order_class.new(
        id: 1,
        items: [existing, { product: 'New', qty: 2 }]
      )

      expect(order.items[0]).to be(existing)
      expect(order.items[1]).to be_a(item_class)
      expect(order.items[1].product).to eq('New')
    end
  end

  describe 'Model can instantiate nested Schema objects' do
    let(:metadata_class) do
      Class.new do
        include EasyTalk::Schema

        def self.name = 'Metadata'

        define_schema do
          property :source, String
          property :version, Integer
        end
      end
    end

    let(:model_class) do
      meta = metadata_class
      Class.new do
        include EasyTalk::Model

        define_singleton_method(:name) { 'Record' }

        define_schema do
          property :title, String
          property :meta, meta
        end
      end
    end

    it 'auto-instantiates a nested Schema object from a hash' do
      record = model_class.new(
        title: 'Test',
        meta: { source: 'api', version: 2 }
      )

      expect(record.meta).to be_a(metadata_class)
      expect(record.meta.source).to eq('api')
      expect(record.meta.version).to eq(2)
    end
  end
end
