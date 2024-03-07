# frozen_string_literal: true

require 'spec_helper'
require 'easy_talk/builders/number_builder'

RSpec.describe EasyTalk::Builders::ObjectBuilder do
  it 'returns a bare minimal json object' do
    schema_definition = EasyTalk::SchemaDefinition.new(Class.new, {})
    builder = described_class.new(schema_definition).build

    expect(builder).to eq({ type: 'object' })
  end

  it 'returns a json object with title' do
    schema_definition = EasyTalk::SchemaDefinition.new(Class.new, { title: 'User' })
    builder = described_class.new(schema_definition).build

    expect(builder).to eq({ type: 'object', title: 'User' })
  end

  context 'with properties' do
    it 'returns a json object with properties' do
      schema_definition = EasyTalk::SchemaDefinition.new(Class.new, {})
      schema_definition.property(:name, String)
      schema_definition.property(:age, Integer)

      builder = described_class.new(schema_definition).build

      expect(builder).to be_a(Hash)
      expect(builder[:type]).to eq('object')
      expect(builder[:properties]).to be_a(Hash)
      expect(builder[:properties][:name]).to be_a(EasyTalk::Property)
      expect(builder[:properties][:age]).to be_a(EasyTalk::Property)
      expect(builder[:properties][:name].type).to eq(String)
      expect(builder[:properties][:age].type).to eq(Integer)
      expect(builder[:properties][:name].name).to eq(:name)
      expect(builder[:properties][:age].name).to eq(:age)
      expect(builder[:properties][:name].options).to eq({})
      expect(builder[:properties][:age].options).to eq({})
    end
  end
end
