# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::Configuration do
  describe 'default values' do
    subject(:config) { described_class.new }

    it 'defaults default_additional_properties to false' do
      expect(config.default_additional_properties).to be false
    end

    it 'defaults nilable_is_optional to false' do
      expect(config.nilable_is_optional).to be false
    end

    it 'defaults auto_validations to true' do
      expect(config.auto_validations).to be true
    end

    it 'defaults property_naming_strategy to identity' do
      expect(config.property_naming_strategy).to eq(EasyTalk::NamingStrategies::IDENTITY)
    end

    it 'defaults validation_adapter to :active_model' do
      expect(config.validation_adapter).to eq(:active_model)
    end

    it 'defaults schema_version to :none' do
      expect(config.schema_version).to eq(:none)
    end

    it 'defaults schema_id to nil' do
      expect(config.schema_id).to be_nil
    end

    it 'defaults use_refs to false' do
      expect(config.use_refs).to be false
    end

    it 'defaults default_error_format to :flat' do
      expect(config.default_error_format).to eq(:flat)
    end

    it 'defaults error_type_base_uri to about:blank' do
      expect(config.error_type_base_uri).to eq('about:blank')
    end

    it 'defaults include_error_codes to true' do
      expect(config.include_error_codes).to be true
    end
  end

  describe '#schema_uri' do
    subject(:config) { described_class.new }

    it 'returns nil when schema_version is :none' do
      config.schema_version = :none
      expect(config.schema_uri).to be_nil
    end

    it 'returns draft 2020-12 URI' do
      config.schema_version = :draft202012
      expect(config.schema_uri).to eq('https://json-schema.org/draft/2020-12/schema')
    end

    it 'returns draft 2019-09 URI' do
      config.schema_version = :draft201909
      expect(config.schema_uri).to eq('https://json-schema.org/draft/2019-09/schema')
    end

    it 'returns draft 7 URI' do
      config.schema_version = :draft7
      expect(config.schema_uri).to eq('http://json-schema.org/draft-07/schema#')
    end

    it 'returns draft 6 URI' do
      config.schema_version = :draft6
      expect(config.schema_uri).to eq('http://json-schema.org/draft-06/schema#')
    end

    it 'returns draft 4 URI' do
      config.schema_version = :draft4
      expect(config.schema_uri).to eq('http://json-schema.org/draft-04/schema#')
    end

    it 'returns custom URI as string when unknown version' do
      config.schema_version = 'https://custom.schema/v1'
      expect(config.schema_uri).to eq('https://custom.schema/v1')
    end
  end

  describe '#property_naming_strategy=' do
    subject(:config) { described_class.new }

    it 'accepts :snake_case symbol' do
      config.property_naming_strategy = :snake_case
      expect(config.property_naming_strategy).to eq(EasyTalk::NamingStrategies::SNAKE_CASE)
    end

    it 'accepts :camel_case symbol' do
      config.property_naming_strategy = :camel_case
      expect(config.property_naming_strategy).to eq(EasyTalk::NamingStrategies::CAMEL_CASE)
    end

    it 'accepts :pascal_case symbol' do
      config.property_naming_strategy = :pascal_case
      expect(config.property_naming_strategy).to eq(EasyTalk::NamingStrategies::PASCAL_CASE)
    end

    it 'accepts custom proc' do
      custom_strategy = ->(name) { name.to_s.upcase.to_sym }
      config.property_naming_strategy = custom_strategy
      expect(config.property_naming_strategy).to eq(custom_strategy)
    end
  end

  describe '#register_type' do
    subject(:config) { described_class.new }

    let(:custom_type) { Class.new }
    let(:custom_builder) { Class.new(EasyTalk::Builders::BaseBuilder) }

    after do
      # Clean up registered type
      EasyTalk::Builders::Registry.instance_variable_get(:@registry)&.delete(custom_type)
    end

    it 'delegates to Builders::Registry.register' do
      expect(EasyTalk::Builders::Registry).to receive(:register).with(custom_type, custom_builder, collection: false)
      config.register_type(custom_type, custom_builder)
    end

    it 'supports collection option' do
      expect(EasyTalk::Builders::Registry).to receive(:register).with(custom_type, custom_builder, collection: true)
      config.register_type(custom_type, custom_builder, collection: true)
    end
  end
end

RSpec.describe EasyTalk do
  describe '.configuration' do
    it 'returns the same configuration instance' do
      config1 = described_class.configuration
      config2 = described_class.configuration
      expect(config1).to be(config2)
    end

    it 'creates a new configuration if none exists' do
      described_class.instance_variable_set(:@configuration, nil)
      expect(described_class.configuration).to be_a(EasyTalk::Configuration)
    end
  end

  describe '.configure' do
    after do
      # Reset configuration after each test
      described_class.instance_variable_set(:@configuration, nil)
    end

    it 'yields the configuration object' do
      expect { |b| described_class.configure(&b) }
        .to yield_with_args(instance_of(EasyTalk::Configuration))
    end

    it 'allows setting configuration values' do
      described_class.configure do |config|
        config.default_additional_properties = true
        config.nilable_is_optional = true
        config.auto_validations = false
      end

      config = described_class.configuration
      expect(config.default_additional_properties).to be true
      expect(config.nilable_is_optional).to be true
      expect(config.auto_validations).to be false
    end

    it 'maintains configuration between calls' do
      described_class.configure { |config| config.default_additional_properties = true }
      described_class.configure { |config| config.nilable_is_optional = true }

      config = described_class.configuration
      expect(config.default_additional_properties).to be true
      expect(config.nilable_is_optional).to be true
    end
  end

  describe 'default_additional_properties affects schema generation' do
    after do
      described_class.instance_variable_set(:@configuration, nil)
    end

    it 'sets additionalProperties to false by default' do
      test_class = Class.new do
        include EasyTalk::Model
        def self.name = 'TestModel'

        define_schema do
          property :name, String
        end
      end

      expect(test_class.json_schema['additionalProperties']).to be false
    end

    it 'sets additionalProperties to true when configured' do
      described_class.configure do |config|
        config.default_additional_properties = true
      end

      test_class = Class.new do
        include EasyTalk::Model
        def self.name = 'TestModel'

        define_schema do
          property :name, String
        end
      end

      expect(test_class.json_schema['additionalProperties']).to be true
    end

    it 'allows explicit override in schema even when config is true' do
      described_class.configure do |config|
        config.default_additional_properties = true
      end

      test_class = Class.new do
        include EasyTalk::Model
        def self.name = 'TestModel'

        define_schema do
          additional_properties false
          property :name, String
        end
      end

      expect(test_class.json_schema['additionalProperties']).to be false
    end
  end
end
