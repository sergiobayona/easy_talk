# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::Model do
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
        property :email, Hash do
          property :address, String
          property :verified, String
        end
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
          type: :object,
          constraints: {},
          properties: {
            address: {
              type: String,
              constraints: {}
            },
            verified: {
              type: String,
              constraints: {}
            }
          }
        }
      }
    }
  end

  it 'returns the name' do
    expect(user.schema_definition.name).to eq 'User'
  end

  # it 'returns the schema' do
  #   expect(user.schema_definition.schema).to eq(expected_internal_schema)
  # end

  it "returns the function name 'User'" do
    expect(user.function_name).to eq('User')
  end

  it 'does not inherit schema' do
    expect(user.inherits_schema?).to eq(false)
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

      # FIXME: This test is failing because the email property hash keys are strings.
      pending "returns the model's properties' values" do
        expect(employee.properties).to eq(name: 'John', age: 21, email: { address: 'john@test.com', verified: 'false' })
      end

      it 'returns a property' do
        expect(employee.name).to eq('John')
      end

      it 'returns a hash type property' do
        expect(employee.email).to eq(address: 'john@test.com', verified: 'false')
      end

      it 'is valid' do
        expect(employee.valid?).to eq(true)
      end
    end
  end
end
