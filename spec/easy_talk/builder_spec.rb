# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::Builder do
  let(:my_class) do
    Class.new do
      include EasyTalk::Model
      def self.name
        'User'
      end

      define_schema do
        title 'Title'
        property :name, String
      end
    end
  end

  it 'returns itself without errors' do
    schema_definition = EasyTalk::SchemaDefinition.new(:name)
    builder = described_class.new(schema_definition)
    expect(builder).to be_a(EasyTalk::Builder)
    expect(builder.schema).to eq({ type: 'object' })
    expect(builder.json_schema).to eq('{"type":"object"}')
  end

  context 'when building a schema' do
    it 'includes a title' do
      schema_definition = my_class.schema_definition
      builder = described_class.new(schema_definition).build_schema
      expect(builder).to include({ title: 'Title' })
      expect(builder).to include({ type: 'object' })
      expect(builder).to include({ required: [:name] })
    end
  end
end
