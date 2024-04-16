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
      end
    end
  end

  it 'returns the name and the internal raw schema definition' do
    expect(user.schema_definition.name).to eq 'User'
    expect(user.schema_definition.schema).to eq({
                                                  title: 'User',
                                                  properties: {
                                                    name: {
                                                      type: String,
                                                      constraints: {}
                                                    },
                                                    age: {
                                                      type: Integer,
                                                      constraints: {}
                                                    }
                                                  }
                                                })
  end

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

  describe 'validating a JSON object' do
    it 'validates the JSON object against the schema' do
      expect(user.validate_json({ name: 'John', age: 21 })).to eq(true)
    end

    it 'fails validation of the JSON object against the schema' do
      expect(user.validate_json({ name: 'John', age: '21' })).to eq(false)
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

  context 'the schema' do
    it 'returns the validated internal representation of the schema' do
      expect(user.schema).to be_a(Hash)
      expect(user.schema[:type]).to eq('object')
      expect(user.schema[:title]).to eq('User')
      expect(user.schema[:properties]).to be_a(Hash)
      name_property = user.schema[:properties][:name]
      expect(name_property).to be_a(EasyTalk::Property)
      expect(name_property.name).to eq(:name)
      expect(name_property.type).to eq(String)
      expect(name_property.constraints).to eq({})
      age_property = user.schema[:properties][:age]
      expect(age_property).to be_a(EasyTalk::Property)
      expect(age_property.name).to eq(:age)
      expect(age_property.type).to eq(Integer)
      expect(age_property.constraints).to eq({})
    end

    it 'returns the JSON schema' do
      expect(user.json_schema).to include_json({
                                                 'properties': {
                                                   'age': {
                                                     'type': 'integer'
                                                   },
                                                   'name': {
                                                     'type': 'string'
                                                   }
                                                 },
                                                 'required': %w[name age],
                                                 'title': 'User',
                                                 'type': 'object'
                                               })
    end
  end
end
