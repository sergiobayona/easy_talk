# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::ValidationAdapters::NoneAdapter do
  let(:test_class) do
    Class.new do
      include EasyTalk::Model
      def self.name = 'NoneAdapterTest'
    end
  end

  describe '.build_validations' do
    it 'does not add any validations' do
      initial_validators_count = test_class.validators.length

      described_class.build_validations(test_class, :name, String, { min_length: 5 })

      # No new validators should be added
      expect(test_class.validators.length).to eq(initial_validators_count)
    end
  end

  describe '#apply_validations' do
    it 'returns without doing anything' do
      adapter = described_class.new(test_class, :name, String, { min_length: 5 })
      expect { adapter.apply_validations }.not_to raise_error
    end
  end

  context 'when used via define_schema' do
    let(:test_class) do
      Class.new do
        include EasyTalk::Model
        def self.name = 'NoneAdapterSchemaTest'

        define_schema(validations: :none) do
          property :name, String, min_length: 5
          property :age, Integer, minimum: 0
        end
      end
    end

    it 'does not apply validations' do
      # Invalid according to constraints, but should pass because no validations
      instance = test_class.new(name: 'X', age: -5)
      expect(instance.valid?).to be true
    end

    it 'still generates correct schema' do
      schema = test_class.json_schema

      expect(schema['properties']['name']['minLength']).to eq(5)
      expect(schema['properties']['age']['minimum']).to eq(0)
    end
  end
end
