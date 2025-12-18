# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Schema ID ($id keyword)' do
  after do
    # Reset configuration after each test
    EasyTalk.configuration.schema_id = nil
    EasyTalk.configuration.schema_version = :none
  end

  describe 'Configuration' do
    it 'defaults schema_id to nil' do
      expect(EasyTalk.configuration.schema_id).to be_nil
    end

    it 'accepts a URI string' do
      EasyTalk.configuration.schema_id = 'https://example.com/schemas/user.json'
      expect(EasyTalk.configuration.schema_id).to eq('https://example.com/schemas/user.json')
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

    context 'when schema_id is nil (default)' do
      it 'does not include $id in the output' do
        expect(test_class.json_schema).not_to have_key('$id')
      end
    end

    context 'when schema_id is set globally' do
      before do
        EasyTalk.configuration.schema_id = 'https://example.com/schemas/test.json'
      end

      it 'includes $id in the output' do
        expect(test_class.json_schema['$id']).to eq('https://example.com/schemas/test.json')
      end

      it 'places $id after $schema when both are present' do
        EasyTalk.configuration.schema_version = :draft202012
        schema = test_class.json_schema
        keys = schema.keys
        expect(keys[0]).to eq('$schema')
        expect(keys[1]).to eq('$id')
      end

      it 'places $id first when no $schema is present' do
        schema = test_class.json_schema
        expect(schema.keys.first).to eq('$id')
      end
    end
  end

  describe 'Per-model override' do
    context 'when model specifies schema_id' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'TestModelWithId'
          end

          define_schema do
            schema_id 'https://example.com/models/user.schema.json'
            title 'Test Model'
            property :name, String
          end
        end
      end

      it 'uses the per-model schema_id' do
        expect(test_class.json_schema['$id']).to eq('https://example.com/models/user.schema.json')
      end
    end

    context 'when model overrides global configuration' do
      before do
        EasyTalk.configuration.schema_id = 'https://example.com/global.json'
      end

      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'TestModelOverride'
          end

          define_schema do
            schema_id 'https://example.com/override.json'
            property :name, String
          end
        end
      end

      it 'uses the per-model schema_id instead of global' do
        expect(test_class.json_schema['$id']).to eq('https://example.com/override.json')
      end
    end

    context 'when model explicitly sets :none to override global' do
      before do
        EasyTalk.configuration.schema_id = 'https://example.com/global.json'
      end

      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'TestModelNoId'
          end

          define_schema do
            schema_id :none
            property :name, String
          end
        end
      end

      it 'does not include $id when explicitly set to :none' do
        expect(test_class.json_schema).not_to have_key('$id')
      end
    end
  end

  describe 'Nested models' do
    before do
      EasyTalk.configuration.schema_id = 'https://example.com/user.json'
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

    it 'includes $id only at the root level' do
      schema = user_class.json_schema
      expect(schema['$id']).to eq('https://example.com/user.json')
    end

    it 'does not include $id in nested object schemas' do
      schema = user_class.json_schema
      address_schema = schema['properties']['address']
      expect(address_schema).not_to have_key('$id')
    end
  end

  describe 'Combined with $schema' do
    let(:test_class) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'CombinedModel'
        end

        define_schema do
          schema_version :draft202012
          schema_id 'https://example.com/combined.json'
          property :name, String
        end
      end
    end

    it 'includes both $schema and $id' do
      schema = test_class.json_schema
      expect(schema['$schema']).to eq('https://json-schema.org/draft/2020-12/schema')
      expect(schema['$id']).to eq('https://example.com/combined.json')
    end

    it 'places $schema before $id' do
      schema = test_class.json_schema
      keys = schema.keys
      schema_index = keys.index('$schema')
      id_index = keys.index('$id')
      expect(schema_index).to be < id_index
    end
  end

  describe 'URI formats' do
    context 'with absolute URI' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'AbsoluteUriModel'
          end

          define_schema do
            schema_id 'https://example.com/schemas/v1/user.schema.json'
            property :name, String
          end
        end
      end

      it 'accepts absolute URIs' do
        expect(test_class.json_schema['$id']).to eq('https://example.com/schemas/v1/user.schema.json')
      end
    end

    context 'with relative URI' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'RelativeUriModel'
          end

          define_schema do
            schema_id 'user.schema.json'
            property :name, String
          end
        end
      end

      it 'accepts relative URIs' do
        expect(test_class.json_schema['$id']).to eq('user.schema.json')
      end
    end

    context 'with URN format' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'UrnModel'
          end

          define_schema do
            schema_id 'urn:example:user-schema'
            property :name, String
          end
        end
      end

      it 'accepts URN format' do
        expect(test_class.json_schema['$id']).to eq('urn:example:user-schema')
      end
    end
  end
end
