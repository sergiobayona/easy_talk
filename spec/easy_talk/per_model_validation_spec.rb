# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Per-model validation configuration' do
  describe 'define_schema(validations: false)' do
    let(:test_class) do
      Class.new do
        include EasyTalk::Model

        def self.name = 'NoValidationModel'

        define_schema(validations: false) do
          property :name, String, min_length: 5
          property :age, Integer, minimum: 18
        end
      end
    end

    it 'does not apply validations' do
      # Values violate constraints but should still be valid
      instance = test_class.new(name: 'X', age: 5)
      expect(instance.valid?).to be true
    end

    it 'still generates correct schema' do
      schema = test_class.json_schema

      expect(schema['properties']['name']['minLength']).to eq(5)
      expect(schema['properties']['age']['minimum']).to eq(18)
    end

    it 'still has required properties in schema' do
      schema = test_class.json_schema
      expect(schema['required']).to include('name', 'age')
    end
  end

  describe 'define_schema(validations: true)' do
    let(:test_class) do
      Class.new do
        include EasyTalk::Model

        def self.name = 'ExplicitValidationModel'

        define_schema(validations: true) do
          property :name, String, min_length: 5
        end
      end
    end

    it 'applies validations' do
      instance = test_class.new(name: 'X')
      expect(instance.valid?).to be false
      expect(instance.errors[:name]).not_to be_empty
    end
  end

  describe 'define_schema(validations: :none)' do
    let(:test_class) do
      Class.new do
        include EasyTalk::Model

        def self.name = 'NoneAdapterModel'

        define_schema(validations: :none) do
          property :name, String, min_length: 5
        end
      end
    end

    it 'uses the NoneAdapter' do
      instance = test_class.new(name: 'X')
      expect(instance.valid?).to be true
    end
  end

  describe 'define_schema(validations: :active_model)' do
    let(:test_class) do
      Class.new do
        include EasyTalk::Model

        def self.name = 'ActiveModelAdapterModel'

        define_schema(validations: :active_model) do
          property :name, String, min_length: 5
        end
      end
    end

    it 'uses the ActiveModelAdapter' do
      instance = test_class.new(name: 'X')
      expect(instance.valid?).to be false
    end
  end

  describe 'define_schema(validations: CustomAdapter)' do
    let(:custom_adapter) do
      Class.new(EasyTalk::ValidationAdapters::Base) do
        def apply_validations
          # Only add presence validation, ignoring all constraints
          @klass.validates @property_name, presence: true
        end
      end
    end

    let(:test_class) do
      adapter = custom_adapter
      Class.new do
        include EasyTalk::Model

        def self.name = 'CustomAdapterModel'

        define_schema(validations: adapter) do
          property :name, String, min_length: 100 # Would normally fail for short strings
        end
      end
    end

    it 'uses the custom adapter' do
      # Empty name should fail (presence validation from custom adapter)
      instance = test_class.new(name: nil)
      expect(instance.valid?).to be false
      expect(instance.errors[:name]).to include("can't be blank")
    end

    it 'does not apply constraints that custom adapter ignores' do
      # Short name would fail min_length but custom adapter ignores it
      instance = test_class.new(name: 'Short')
      expect(instance.valid?).to be true
    end
  end

  describe 'invalid validations option' do
    it 'raises ArgumentError for invalid type' do
      expect do
        Class.new do
          include EasyTalk::Model

          def self.name = 'InvalidOptionsModel'

          define_schema(validations: 123) do
            property :name, String
          end
        end
      end.to raise_error(ArgumentError, /Invalid validations option/)
    end
  end

  describe 'respects global auto_validations setting' do
    let(:original_auto_validations) { EasyTalk.configuration.auto_validations }

    before { EasyTalk.configuration.auto_validations = original_auto_validations }

    after { EasyTalk.configuration.auto_validations = original_auto_validations }

    context 'when auto_validations is false globally' do
      before { EasyTalk.configuration.auto_validations = false }

      it 'does not apply validations by default' do
        test_class = Class.new do
          include EasyTalk::Model

          def self.name = 'GlobalDisabledModel'

          define_schema do
            property :name, String, min_length: 5
          end
        end

        instance = test_class.new(name: 'X')
        expect(instance.valid?).to be true
      end

      it 'can be overridden with validations: true' do
        test_class = Class.new do
          include EasyTalk::Model

          def self.name = 'OverrideGlobalModel'

          define_schema(validations: true) do
            property :name, String, min_length: 5
          end
        end

        instance = test_class.new(name: 'X')
        expect(instance.valid?).to be false
      end
    end
  end

  describe 'respects global validation_adapter setting' do
    let(:original_adapter) { EasyTalk.configuration.validation_adapter }

    before { EasyTalk.configuration.validation_adapter = original_adapter }

    after { EasyTalk.configuration.validation_adapter = original_adapter }

    it 'uses the configured adapter' do
      EasyTalk.configuration.validation_adapter = :none

      test_class = Class.new do
        include EasyTalk::Model

        def self.name = 'GlobalAdapterModel'

        define_schema do
          property :name, String, min_length: 5
        end
      end

      instance = test_class.new(name: 'X')
      expect(instance.valid?).to be true
    end
  end
end
