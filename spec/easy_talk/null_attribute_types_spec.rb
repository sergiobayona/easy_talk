# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'null vs optional' do
  context 'for PORO' do
    let(:address) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'User'
        end

        define_schema do
          property :name, String
          property :age, T.nilable(Integer)
          property :email, String, optional: true
        end
      end
    end

    it 'has age as type or null' do
      expect(address.json_schema['properties']['age']['type']).to eq(%w[integer null])
    end

    it 'includes age in the required array' do
      expect(address.json_schema['required']).to include('age')
    end

    it 'includes name in the required array' do
      expect(address.json_schema['required']).to include('name')
    end

    it 'does not include email in the required array' do
      expect(address.json_schema['required']).not_to include('email')
    end

    it 'returns a valid json schema' do
      expect(address.json_schema).to eq(
        {
          'type' => 'object',
          'properties' => {
            'name' => { 'type' => 'string' },
            'age' => { 'type' => %w[integer null] },
            'email' => { 'type' => 'string' }
          },
          'additionalProperties' => false,
          'required' => %w[name age]
        }
      )
    end
  end
end
