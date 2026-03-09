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

  # Regression: PR #169
  describe 'false value preservation' do
    let(:schema_class) do
      Class.new do
        include EasyTalk::Schema

        def self.name = 'FeatureFlags'

        define_schema do
          property :enabled,  T::Boolean
          property :archived, T::Boolean
          property :count,    Integer
        end
      end
    end

    describe 'symbol-key assignment' do
      it 'preserves false for a boolean property' do
        instance = schema_class.new(enabled: false)
        expect(instance.enabled).to be(false),
                                    "Expected false but got #{instance.enabled.inspect} — " \
                                    'false was silently lost via the || lookup'
      end

      it 'preserves false when multiple booleans are passed' do
        instance = schema_class.new(enabled: false, archived: false)
        expect(instance.enabled).to be(false)
        expect(instance.archived).to be(false)
      end

      it 'preserves true (sanity check — truthy values are unaffected)' do
        instance = schema_class.new(enabled: true)
        expect(instance.enabled).to be(true)
      end

      it 'preserves 0 (sanity check — 0 is truthy in Ruby, so unaffected)' do
        instance = schema_class.new(count: 0)
        expect(instance.count).to eq(0)
      end
    end

    describe 'string-key assignment' do
      it 'preserves false when passed with string keys' do
        instance = schema_class.new('enabled' => false)
        expect(instance.enabled).to be(false)
      end
    end

    describe 'mixed false and nil' do
      it 'distinguishes between an explicitly passed false and an absent key' do
        with_false = schema_class.new(enabled: false)
        with_nil   = schema_class.new(enabled: nil)
        absent     = schema_class.new

        expect(with_false.enabled).to be(false)
        expect(with_nil.enabled).to be_nil
        expect(absent.enabled).to be_nil
      end
    end
  end

  # Regression: PR #170
  describe 'mutable default values' do
    context 'with an Array default' do
      let(:schema_class) do
        Class.new do
          include EasyTalk::Schema

          def self.name = 'Contract'

          define_schema do
            property :tags, T::Array[String], default: []
          end
        end
      end

      it 'gives each instance its own copy of the default array' do
        a = schema_class.new
        b = schema_class.new

        a.tags << 'urgent'

        expect(b.tags).to eq([]),
                          "b.tags was corrupted by a mutation: #{b.tags.inspect}. " \
                          'The mutable default array is shared across instances.'
      end

      it 'does not share the same object between instances' do
        a = schema_class.new
        b = schema_class.new

        expect(a.tags.object_id).not_to eq(b.tags.object_id),
                                        'Both instances reference the identical Array object for :tags'
      end
    end

    context 'with a Hash default' do
      let(:schema_class) do
        Class.new do
          include EasyTalk::Schema

          def self.name = 'MetaContract'

          define_schema do
            property :metadata, String, default: { 'env' => 'production' }
          end
        end
      end

      it 'gives each instance its own copy of the default hash' do
        a = schema_class.new
        b = schema_class.new

        a.metadata['injected'] = 'surprise'

        expect(b.metadata).to eq({ 'env' => 'production' }),
                              "b.metadata was corrupted by a mutation: #{b.metadata.inspect}. " \
                              'The mutable default hash is shared across instances.'
      end
    end
  end

  # Regression: PR #172
  describe 'shared SchemaBase behavior' do
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
end
