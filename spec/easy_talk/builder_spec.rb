# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::Builder do
  it 'returns itself without errors' do
    schema_definition = EasyTalk::SchemaDefinition.new(Object, {})
    builder = described_class.new(schema_definition)
    expect(builder).to be_a(EasyTalk::Builder)
    expect(builder.schema).to eq({ type: 'object' })
    expect(builder.json_schema).to eq('{"type":"object"}')
  end

  context 'when building a schema' do
    it 'includes a title' do
      schema_definition = EasyTalk::SchemaDefinition.new(Object, { title: 'Title' })
      builder = described_class.new(schema_definition).build_schema
      expect(builder).to eq({
                              title: 'Title',
                              type: 'object'
                            })
    end

    it 'includes a description' do
      schema_definition = EasyTalk::SchemaDefinition.new(Object, { description: 'Description' })
      builder = described_class.new(schema_definition).build_schema
      expect(builder).to eq({
                              description: 'Description',
                              type: 'object'
                            })
    end

    it 'includes the property' do
      schema_definition = EasyTalk::SchemaDefinition.new(Object, { properties: { name: { type: String } } })
      builder = described_class.new(schema_definition).build_schema
      expect(builder).to be_a(Hash)
      expect(builder[:properties]).to be_a(Hash)
      expect(builder[:properties][:name]).to be_a(EasyTalk::Property)
    end
  end
end
