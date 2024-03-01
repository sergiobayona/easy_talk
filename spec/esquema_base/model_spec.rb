# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EsquemaBase::Model do
  let(:user) do
    Class.new do
      include EsquemaBase::Model
    end
  end

  describe '.schema_definition' do
    it 'returns the schema definition' do
      expect(user.schema_definition).to eq({})
    end
  end

  describe '.json_schema' do
    it 'returns the JSON schema' do
      expect(user.schema).to eq({})
    end
  end

  describe '.schema_definition' do
    it 'enhances the schema using the provided block' do
      user.define_schema do
        title 'User'
        description 'A user of the system'
        property :name, String, title: "Person's Name"
        property :tags, T::Array[String], min_items: 1, title: 'Tags'
      end

      properties = user.schema_definition[:properties]

      # expect(properties).to be_a(Hash)
      # expect(user.schema_definition[:title]).to eq('User')
      # expect(user.schema_definition[:description]).to eq('A user of the system')
      # expect(properties[:name]).to eq(title: "Person's Name", type: 'string')
      # expect(properties[:email]).to eq(title: "Person's Mailing Address", type: 'string', format: 'email')
    end
  end
end
