# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'additional properties' do
  context 'when additional_properties true' do
    let(:company) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'Company'
        end

        define_schema do
          property :name, String
          additional_properties true
        end
      end
    end

    describe 'schema generation' do
      it 'includes additionalProperties: true in the schema' do
        expect(company.json_schema).to include(
          'additionalProperties' => true
        )
      end

      it 'maintains defined properties in the schema' do
        expect(company.json_schema['properties']).to include(
          'name' => { 'type' => 'string' }
        )
      end
    end

    describe 'instance behavior' do
      let(:instance) { company.new }

      context 'with defined properties' do
        it 'allows setting and getting defined properties' do
          instance.name = 'Acme Corp'
          expect(instance.name).to eq('Acme Corp')
        end

        it 'allows setting defined properties in constructor' do
          instance = company.new(name: 'Acme Corp')
          expect(instance.name).to eq('Acme Corp')
        end
      end

      context 'with additional properties' do
        it 'allows setting additional properties' do
          instance.custom_field = 'value'
          expect(instance.custom_field).to eq('value')
        end

        it 'allows getting additional properties' do
          instance.instance_variable_set(:@additional_properties, { 'custom_field' => 'value' })
          expect(instance.custom_field).to eq('value')
        end

        it 'allows setting additional properties in constructor' do
          instance = company.new(custom_field: 'value')
          expect(instance.custom_field).to eq('value')
        end

        it 'returns nil for undefined additional properties' do
          expect do
            instance.undefined_property
          end.to raise_error(NoMethodError)
        end

        it 'tracks multiple additional properties' do
          instance.field1 = 'value1'
          instance.field2 = 'value2'
          expect(instance.field1).to eq('value1')
          expect(instance.field2).to eq('value2')
        end
      end

      describe '#respond_to?' do
        it 'returns true for defined properties' do
          expect(instance.respond_to?(:name)).to be true
          expect(instance.respond_to?(:name=)).to be true
        end

        it 'returns true for additional property setters (can always set)' do
          expect(instance.respond_to?(:custom_field=)).to be true
        end

        it 'returns false for additional property getters that have not been set' do
          expect(instance.respond_to?(:custom_field)).to be false
        end

        it 'returns true for additional property getters that have been set' do
          instance.custom_field = 'value'
          expect(instance.respond_to?(:custom_field)).to be true
        end
      end

      describe '#as_json' do
        it 'includes both defined and additional properties' do
          instance.name = 'Acme Corp'
          instance.custom_field = 'value'

          expect(instance.as_json).to include(
            'name' => 'Acme Corp',
            'custom_field' => 'value'
          )
        end

        it 'handles nil values for defined properties' do
          instance.custom_field = 'value'
          expect(instance.as_json).to include(
            'name' => nil,
            'custom_field' => 'value'
          )
        end

        it 'handles complex nested values' do
          instance.nested = { key: 'value' }
          instance.array = [1, 2, 3]

          expect(instance.as_json).to include(
            'nested' => { key: 'value' },
            'array' => [1, 2, 3]
          )
        end
      end
    end
  end

  context 'when additional_properties false' do
    let(:restricted_company) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'RestrictedCompany'
        end

        define_schema do
          property :name, String
          additional_properties false
        end
      end
    end

    describe 'schema generation' do
      it 'includes additionalProperties: false in the schema' do
        expect(restricted_company.json_schema).to include(
          'additionalProperties' => false
        )
      end
    end

    describe 'instance behavior' do
      let(:instance) { restricted_company.new }

      it 'allows setting defined properties' do
        instance.name = 'Acme Corp'
        expect(instance.name).to eq('Acme Corp')
      end

      it 'raises NoMethodError when setting undefined properties' do
        expect do
          instance.custom_field = 'value'
        end.to raise_error(NoMethodError)
      end

      it 'raises NoMethodError when getting undefined properties' do
        expect do
          instance.custom_field
        end.to raise_error(NoMethodError)
      end

      describe '#respond_to?' do
        it 'returns true for defined properties' do
          expect(instance.respond_to?(:name)).to be true
          expect(instance.respond_to?(:name=)).to be true
        end

        it 'returns false for undefined properties' do
          expect(instance.respond_to?(:custom_field)).to be false
          expect(instance.respond_to?(:custom_field=)).to be false
        end
      end
    end
  end

  context 'when additional_properties not specified' do
    let(:default_company) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'DefaultCompany'
        end

        define_schema do
          property :name, String
        end
      end
    end

    describe 'schema generation' do
      it 'does include additionalProperties in the schema' do
        expect(default_company.json_schema).to have_key('additionalProperties')
      end
    end

    describe 'instance behavior' do
      let(:instance) { default_company.new }

      it 'behaves as if additional_properties is false' do
        expect do
          instance.custom_field = 'value'
        end.to raise_error(NoMethodError)
      end
    end
  end
end
