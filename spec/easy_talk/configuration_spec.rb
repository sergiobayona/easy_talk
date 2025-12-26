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
end
