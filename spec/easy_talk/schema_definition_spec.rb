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
    expect(model.schema_definition).to be_a(EasyTalk::SchemaDefinition)
  end

  it 'sets the name' do
    expect(model.schema_definition.name).to eq('Model')
  end

  it 'sets the schema' do
    expect(model.schema_definition.schema).to eq({ title: 'Model', properties: { name: { type: String, constraints: { minimum: 1, maximum: 100 } } } })
  end

  describe 'property' do
    it 'appends a property to the model.schema_definition.schema' do
      model.schema_definition.property(:foo, Integer)
      expect(model.schema_definition.schema[:properties]).to eq({
                                                                  name: {
                                                                    type: String,
                                                                    constraints: {
                                                                      minimum: 1,
                                                                      maximum: 100
                                                                    }
                                                                  },
                                                                  foo: {
                                                                    type: Integer,
                                                                    constraints: {}
                                                                  }
                                                                })
    end
  end

  describe 'keywords' do
    it 'adds a keyword to the model.schema_definition.schema' do
      model.schema_definition.title('Title')
      model.schema_definition.description('Description')
      model.schema_definition.default('Default')
      model.schema_definition.enum(%w[one two three])
      model.schema_definition.pattern('^[0-9]{5}(?:-[0-9]{4})?$')
      model.schema_definition.format('email')
      model.schema_definition.minimum(1)
      model.schema_definition.maximum(100)
      model.schema_definition.min_items(1)
      model.schema_definition.max_items(100)
      model.schema_definition.additional_properties(false)
      model.schema_definition.unique_items(true)
      model.schema_definition.const('Const')
      model.schema_definition.content_media_type('ContentMediaType')
      model.schema_definition.content_encoding('ContentEncoding')

      expect(model.schema_definition.schema[:title]).to eq('Title')
      expect(model.schema_definition.schema[:description]).to eq('Description')
      expect(model.schema_definition.schema[:default]).to eq('Default')
      expect(model.schema_definition.schema[:enum]).to eq(%w[one two three])
      expect(model.schema_definition.schema[:pattern]).to eq('^[0-9]{5}(?:-[0-9]{4})?$')
      expect(model.schema_definition.schema[:format]).to eq('email')
      expect(model.schema_definition.schema[:minimum]).to eq(1)
      expect(model.schema_definition.schema[:maximum]).to eq(100)
      expect(model.schema_definition.schema[:min_items]).to eq(1)
      expect(model.schema_definition.schema[:max_items]).to eq(100)
      expect(model.schema_definition.schema[:additional_properties]).to eq(false)
      expect(model.schema_definition.schema[:unique_items]).to eq(true)
      expect(model.schema_definition.schema[:const]).to eq('Const')
      expect(model.schema_definition.schema[:content_media_type]).to eq('ContentMediaType')
      expect(model.schema_definition.schema[:content_encoding]).to eq('ContentEncoding')
    end
  end
end
