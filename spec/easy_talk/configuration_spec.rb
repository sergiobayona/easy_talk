require 'spec_helper'

RSpec.describe EasyTalk::Configuration do
  describe 'default values' do
    subject(:config) { described_class.new }

    it 'defaults exclude_foreign_keys to false' do
      expect(config.exclude_foreign_keys).to be false
    end

    it 'defaults exclude_associations to false' do
      expect(config.exclude_associations).to be false
    end

    it 'sets default excluded columns' do
      expect(config.excluded_columns).to eq([])
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
        config.exclude_foreign_keys = true
        config.exclude_associations = true
        config.excluded_columns = [:created_at, :updated_at, :deleted_at]
      end

      config = described_class.configuration
      expect(config.exclude_foreign_keys).to be true
      expect(config.exclude_associations).to be true
      expect(config.excluded_columns).to eq([:created_at, :updated_at, :deleted_at])
    end

    it 'maintains configuration between calls' do
      described_class.configure { |config| config.exclude_foreign_keys = true }
      described_class.configure { |config| config.exclude_associations = true }

      config = described_class.configuration
      expect(config.exclude_foreign_keys).to be true
      expect(config.exclude_associations).to be true
    end
  end
end
