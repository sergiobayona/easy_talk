# frozen_string_literal: true

require 'spec_helper'
require 'active_record'
RSpec.describe EasyTalk::Model do
  before do
    # Define Email class for use in testing
    class Email
      include EasyTalk::Model

      define_schema do
        property :address, String
        property :verified, String
      end
    end
  end

  after do
    # Clean up the Email class after tests
    Object.send(:remove_const, :Email) if Object.const_defined?(:Email)
  end

  let(:user) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'User'
      end

      define_schema do
        title 'User'
        property :name, String
        property :age, Integer
        property :email, Email
      end
    end
  end

  let(:expected_internal_schema) do
    {
      title: 'User',
      properties: {
        name: {
          type: String,
          constraints: {}
        },
        age: {
          type: Integer,
          constraints: {}
        },
        email: {
          type: Email,
          constraints: {}
        }
      }
    }
  end

  it 'returns the name' do
    expect(user.schema_definition.name).to eq 'User'
  end

  it 'returns its attributes' do
    expect(user.properties).to eq(%i[name age email])
  end

  it 'returns a ref template' do
    expect(user.ref_template).to eq('#/$defs/User')
  end

  describe '.schema_definition' do
    it 'enhances the schema using the provided block' do
      expect(user.schema_definition).to be_a(EasyTalk::SchemaDefinition)
    end
  end

  context 'when the class name is nil' do
    let(:user) do
      Class.new do
        include EasyTalk::Model

        def self.name
          nil
        end
      end
    end

    it 'raises an error' do
      expect { user.define_schema {} }.to raise_error(ArgumentError, 'The class must have a name')
    end
  end

  context "when the class doesn't have a name" do
    let(:user) do
      Class.new do
        include EasyTalk::Model
      end
    end

    it 'raises an error' do
      expect { user.define_schema {} }.to raise_error(ArgumentError, 'The class must have a name')
    end
  end

  describe 'the schema' do
    it 'returns the validated internal representation of the schema' do
      expect(user.schema).to be_a(Hash)
    end

    it 'returns the validated internal representation of the schema with the correct type' do
      expect(user.schema[:type]).to eq('object')
    end

    it 'returns the validated internal representation of the schema with the correct title' do
      expect(user.schema[:title]).to eq('User')
    end

    it 'returns the validated internal representation of the schema with properties as a hash' do
      expect(user.schema[:properties]).to be_a(Hash)
    end

    describe "the name property's schema" do
      let(:name_property) { user.schema[:properties][:name] }

      it 'returns an instance of EasyTalk::Property' do
        expect(name_property).to be_a(EasyTalk::Property)
      end

      it "returns the name property's name" do
        expect(name_property.name).to eq(:name)
      end

      it "returns the name property's type" do
        expect(name_property.type).to eq(String)
      end

      it "returns the name property's constraints" do
        expect(name_property.constraints).to eq({})
      end
    end

    describe "the age property's schema" do
      let(:age_property) { user.schema[:properties][:age] }

      it 'returns an instance of EasyTalk::Property' do
        expect(age_property).to be_a(EasyTalk::Property)
      end

      it "returns the age property's name" do
        expect(age_property.name).to eq(:age)
      end

      it "returns the age property's type" do
        expect(age_property.type).to eq(Integer)
      end

      it "returns the age property's constraints" do
        expect(age_property.constraints).to eq({})
      end
    end

    describe 'the json schema' do
      let(:expected_json_schema) do
        {
          type: 'object',
          title: 'User',
          properties: {
            name: {
              type: 'string'
            },
            age: {
              type: 'integer'
            },
            email: {
              type: 'object',
              properties: {
                address: {
                  type: 'string'
                },
                verified: {
                  type: 'string'
                }
              }
            }
          }
        }
      end

      let(:employee) { user.new(name: 'John', age: 21, email: { address: 'john@test.com', verified: 'false' }) }

      it 'returns the JSON schema' do
        expect(user.json_schema).to include_json(expected_json_schema)
      end

      it 'returns the model properties' do
        expect(user.properties).to eq(%i[name age email])
      end

      it "returns the model's name" do
        expect(user.name).to eq('User')
      end

      it 'returns a property' do
        expect(employee.name).to eq('John')
      end

      it 'returns a hash type property' do
        expect(employee.email).to eq(address: 'john@test.com', verified: 'false')
      end

      it 'is valid' do
        expect(employee.valid?).to be(true)
      end
    end
  end

  # New tests for the unified approach with ActiveRecord integration
  context 'with ActiveRecord integration', :active_record do
    before(:all) do
      # Set up ActiveRecord test environment
      ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

      ActiveRecord::Schema.define do
        create_table :test_products, force: true do |t|
          t.string :name, null: false
          t.text :description
          t.decimal :price, precision: 10, scale: 2
          t.boolean :active, default: true
          t.timestamps
        end
      end

      # Define the ActiveRecord test class
      class TestProduct < ActiveRecord::Base
        include EasyTalk::Model
      end
    end

    after(:all) do
      # Clean up
      if defined?(ActiveRecord::Base) && ActiveRecord::Base.connected? &&
         ActiveRecord::Base.connection.table_exists?(:test_products)
        ActiveRecord::Base.connection.drop_table(:test_products)
      end
      Object.send(:remove_const, :TestProduct) if Object.const_defined?(:TestProduct)
    end

    it 'automatically generates schema from database columns' do
      expect(TestProduct.schema).to be_a(Hash)
      expect(TestProduct.schema[:type]).to eq('object')
      expect(TestProduct.schema[:properties]).to have_key(:name)
      expect(TestProduct.schema[:properties]).to have_key(:description)
      expect(TestProduct.schema[:properties]).to have_key(:price)
      expect(TestProduct.schema[:properties]).to have_key(:active)
    end

    it 'correctly maps column types to schema types' do
      expect(TestProduct.schema[:properties][:name].type).to eq(String)
      expect(TestProduct.schema[:properties][:description].type.name).to eq('T.nilable(String)')
      expect(TestProduct.schema[:properties][:price].type.name).to eq('T.nilable(Float)')
      expect(TestProduct.schema[:properties][:active].type.name).to eq('T.nilable(T::Boolean)')
    end

    it 'automatically extends ActiveRecord models with ActiveRecordClassMethods' do
      expect(TestProduct).to respond_to(:enhance_schema)
      expect(TestProduct).to respond_to(:schema_enhancements)
      expect(TestProduct).to respond_to(:active_record_schema_definition)
    end

    it 'allows enhancing the auto-generated schema' do
      TestProduct.enhance_schema({
                                   title: 'Enhanced Product',
                                   description: 'A product with enhanced schema'
                                 })

      # Force schema regeneration
      TestProduct.instance_variable_set(:@schema, nil)

      expect(TestProduct.schema[:title]).to eq('Enhanced Product')
      expect(TestProduct.schema[:description]).to eq('A product with enhanced schema')
    end

    it 'allows enhancing specific properties in the schema' do
      TestProduct.enhance_schema({
                                   properties: {
                                     name: {
                                       description: 'Product name',
                                       title: 'Name'
                                     }
                                   }
                                 })

      # Force schema regeneration
      TestProduct.instance_variable_set(:@schema, nil)

      expect(TestProduct.schema[:properties][:name].constraints[:description]).to eq('Product name')
    end

    it 'allows adding virtual properties via schema enhancements' do
      TestProduct.enhance_schema({
                                   properties: {
                                     calculated_value: {
                                       virtual: true,
                                       type: :number,
                                       description: 'A calculated value'
                                     }
                                   }
                                 })

      # Force schema regeneration
      TestProduct.instance_variable_set(:@schema, nil)

      expect(TestProduct.schema[:properties]).to have_key(:calculated_value)
    end

    it 'gives preference to explicit schema definition over database schema' do
      class TestProductWithSchema < ActiveRecord::Base
        self.table_name = 'test_products'
        include EasyTalk::Model

        define_schema do
          title 'Explicit Schema Product'
          property :name, String, description: 'Custom product name'
          property :custom_field, String, description: 'Field not in database'
        end
      end

      expect(TestProductWithSchema.schema[:title]).to eq('Explicit Schema Product')
      expect(TestProductWithSchema.schema[:properties][:name].constraints[:description]).to eq('Custom product name')
      expect(TestProductWithSchema.schema[:properties]).to have_key(:custom_field)

      Object.send(:remove_const, :TestProductWithSchema)
    end
  end

  # Test for the unified schema generation approach
  context 'with unified schema generation' do
    it 'has build_schema as a public class method' do
      test_class = Class.new do
        include EasyTalk::Model

        def self.name = 'TestClass'
      end

      expect(test_class.respond_to?(:build_schema)).to be true
      expect(test_class.method(:build_schema).owner).to eq(EasyTalk::Model::ClassMethods)
    end
  end
end
