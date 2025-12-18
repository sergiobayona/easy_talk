# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Schema version ($schema keyword)' do
  after do
    # Reset configuration after each test
    EasyTalk.configuration.schema_version = :none
  end

  describe 'Configuration' do
    it 'defaults schema_version to :none' do
      expect(EasyTalk.configuration.schema_version).to eq(:none)
    end

    it 'returns nil for schema_uri when schema_version is :none' do
      expect(EasyTalk.configuration.schema_uri).to be_nil
    end

    it 'returns the correct URI for draft202012' do
      EasyTalk.configuration.schema_version = :draft202012
      expect(EasyTalk.configuration.schema_uri).to eq('https://json-schema.org/draft/2020-12/schema')
    end

    it 'returns the correct URI for draft201909' do
      EasyTalk.configuration.schema_version = :draft201909
      expect(EasyTalk.configuration.schema_uri).to eq('https://json-schema.org/draft/2019-09/schema')
    end

    it 'returns the correct URI for draft7' do
      EasyTalk.configuration.schema_version = :draft7
      expect(EasyTalk.configuration.schema_uri).to eq('http://json-schema.org/draft-07/schema#')
    end

    it 'returns the correct URI for draft6' do
      EasyTalk.configuration.schema_version = :draft6
      expect(EasyTalk.configuration.schema_uri).to eq('http://json-schema.org/draft-06/schema#')
    end

    it 'returns the correct URI for draft4' do
      EasyTalk.configuration.schema_version = :draft4
      expect(EasyTalk.configuration.schema_uri).to eq('http://json-schema.org/draft-04/schema#')
    end

    it 'allows custom schema URIs as strings' do
      EasyTalk.configuration.schema_version = 'https://example.com/my-schema'
      expect(EasyTalk.configuration.schema_uri).to eq('https://example.com/my-schema')
    end
  end

  describe 'Global configuration' do
    let(:test_class) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'TestModel'
        end

        define_schema do
          title 'Test Model'
          property :name, String
        end
      end
    end

    context 'when schema_version is :none (default)' do
      it 'does not include $schema in the output' do
        expect(test_class.json_schema).not_to have_key('$schema')
      end
    end

    context 'when schema_version is set globally' do
      before do
        EasyTalk.configuration.schema_version = :draft202012
      end

      it 'includes $schema in the output' do
        expect(test_class.json_schema['$schema']).to eq('https://json-schema.org/draft/2020-12/schema')
      end

      it 'places $schema at the root level' do
        schema = test_class.json_schema
        expect(schema.keys.first).to eq('$schema')
      end
    end
  end

  describe 'Per-model override' do
    context 'when model specifies schema_version' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'TestModelWithVersion'
          end

          define_schema do
            schema_version :draft7
            title 'Test Model'
            property :name, String
          end
        end
      end

      it 'uses the per-model schema_version' do
        expect(test_class.json_schema['$schema']).to eq('http://json-schema.org/draft-07/schema#')
      end
    end

    context 'when model overrides global configuration' do
      before do
        EasyTalk.configuration.schema_version = :draft202012
      end

      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'TestModelOverride'
          end

          define_schema do
            schema_version :draft4
            property :name, String
          end
        end
      end

      it 'uses the per-model schema_version instead of global' do
        expect(test_class.json_schema['$schema']).to eq('http://json-schema.org/draft-04/schema#')
      end
    end

    context 'when model uses custom URI' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'TestModelCustomUri'
          end

          define_schema do
            schema_version 'https://example.com/custom-schema.json'
            property :name, String
          end
        end
      end

      it 'uses the custom URI' do
        expect(test_class.json_schema['$schema']).to eq('https://example.com/custom-schema.json')
      end
    end

    context 'when model explicitly sets :none to override global' do
      before do
        EasyTalk.configuration.schema_version = :draft202012
      end

      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'TestModelNoSchema'
          end

          define_schema do
            schema_version :none
            property :name, String
          end
        end
      end

      it 'does not include $schema when explicitly set to :none' do
        expect(test_class.json_schema).not_to have_key('$schema')
      end
    end
  end

  describe 'Nested models' do
    before do
      EasyTalk.configuration.schema_version = :draft202012
    end

    let(:address_class) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'Address'
        end

        define_schema do
          property :street, String
          property :city, String
        end
      end
    end

    let(:user_class) do
      address = address_class
      Class.new do
        include EasyTalk::Model

        def self.name
          'User'
        end

        define_schema do
          property :name, String
          property :address, address
        end
      end
    end

    it 'includes $schema only at the root level' do
      schema = user_class.json_schema
      expect(schema['$schema']).to eq('https://json-schema.org/draft/2020-12/schema')
    end

    it 'does not include $schema in nested object schemas' do
      schema = user_class.json_schema
      address_schema = schema['properties']['address']
      expect(address_schema).not_to have_key('$schema')
    end
  end

  describe 'SCHEMA_VERSIONS constant' do
    it 'contains all expected draft versions' do
      expected_versions = %i[draft202012 draft201909 draft7 draft6 draft4]
      expect(EasyTalk::Configuration::SCHEMA_VERSIONS.keys).to match_array(expected_versions)
    end

    it 'is frozen' do
      expect(EasyTalk::Configuration::SCHEMA_VERSIONS).to be_frozen
    end
  end
end
