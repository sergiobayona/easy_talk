# frozen_string_literal: true

require 'spec_helper'
require 'easy_talk/model'

RSpec.describe EasyTalk::SchemaDefinition do
  let(:model) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'Model'
      end

      define_schema do
        title 'Model'
        property :name, String, minimum: 1, maximum: 100
      end
    end
  end

  it 'sets the klass and model.schema_definition.schema' do
    expect(model.schema_definition).to be_a(described_class)
  end

  it 'sets the name' do
    expect(model.schema_definition.name).to eq('Model')
  end

  it 'sets the schema' do
    expect(model.schema_definition.schema).to eq({ title: 'Model', properties: { name: { type: String, constraints: { minimum: 1, maximum: 100 } } }, additional_properties: false })
  end

  describe 'property' do
    let(:expected_schema) do
      {
        properties: {
          foo: {
            constraints: {},
            type: Integer
          },
          name: {
            constraints: {
              maximum: 100,
              minimum: 1
            },
            type: String
          }
        },
        title: 'Model',
        additional_properties: false
      }
    end

    it 'appends a property to the model.schema_definition.schema' do
      model.schema_definition.property(:foo, Integer)
      expect(model.schema_definition.schema).to eq(expected_schema)
    end
  end

  describe 'keywords' do
    it 'sets the title' do
      model.schema_definition.title('Title')
      expect(model.schema_definition.schema[:title]).to eq('Title')
    end

    it 'sets the description' do
      model.schema_definition.description('Description')
      expect(model.schema_definition.schema[:description]).to eq('Description')
    end

    it 'sets the default' do
      model.schema_definition.default('Default')
      expect(model.schema_definition.schema[:default]).to eq('Default')
    end

    it 'sets the enum' do
      model.schema_definition.enum(%w[one two three])
      expect(model.schema_definition.schema[:enum]).to eq(%w[one two three])
    end

    it 'sets the pattern' do
      model.schema_definition.pattern('^[0-9]{5}(?:-[0-9]{4})?$')
      expect(model.schema_definition.schema[:pattern]).to eq('^[0-9]{5}(?:-[0-9]{4})?$')
    end

    it 'sets the format' do
      model.schema_definition.format('email')
      expect(model.schema_definition.schema[:format]).to eq('email')
    end

    it 'sets the minimum' do
      model.schema_definition.minimum(1)
      expect(model.schema_definition.schema[:minimum]).to eq(1)
    end

    it 'sets the maximum' do
      model.schema_definition.maximum(100)
      expect(model.schema_definition.schema[:maximum]).to eq(100)
    end

    it 'sets the min_items' do
      model.schema_definition.min_items(1)
      expect(model.schema_definition.schema[:min_items]).to eq(1)
    end

    it 'sets the max_items' do
      model.schema_definition.max_items(100)
      expect(model.schema_definition.schema[:max_items]).to eq(100)
    end

    it 'sets additional_properties' do
      model.schema_definition.additional_properties(false)
      expect(model.schema_definition.schema[:additional_properties]).to be(false)
    end

    it 'sets unique_items' do
      model.schema_definition.unique_items(true)
      expect(model.schema_definition.schema[:unique_items]).to be(true)
    end

    it 'sets const' do
      model.schema_definition.const('Const')
      expect(model.schema_definition.schema[:const]).to eq('Const')
    end

    it 'sets content_media_type' do
      model.schema_definition.content_media_type('ContentMediaType')
      expect(model.schema_definition.schema[:content_media_type]).to eq('ContentMediaType')
    end

    it 'sets content_encoding' do
      model.schema_definition.content_encoding('ContentEncoding')
      expect(model.schema_definition.schema[:content_encoding]).to eq('ContentEncoding')
    end
  end

  describe 'compose' do
    let(:subschema) do
      {
        title: 'Subschema',
        properties: {
          foo: {
            constraints: {},
            type: Integer
          }
        }
      }
    end

    let(:expected_schema) do
      {
        properties: {
          name: {
            constraints: {
              maximum: 100,
              minimum: 1
            },
            type: String
          }
        },
        subschemas: [subschema],
        title: 'Model',
        additional_properties: false
      }
    end

    it 'appends a subschema to the model.schema_definition.schema' do
      model.schema_definition.compose(subschema)
      expect(model.schema_definition.schema).to eq(expected_schema)
    end
  end

  describe 'with invalid property name' do
    it 'raises an error when it starts with a number' do
      expect { model.schema_definition.property('1name', String) }.to raise_error(EasyTalk::InvalidPropertyNameError)
    end

    it 'raises an error when it contains a special character' do
      expect { model.schema_definition.property('name!', String) }.to raise_error(EasyTalk::InvalidPropertyNameError)
    end

    it 'raises an error when it contains a space' do
      expect { model.schema_definition.property('name name', String) }.to raise_error(EasyTalk::InvalidPropertyNameError)
    end
  end
end
