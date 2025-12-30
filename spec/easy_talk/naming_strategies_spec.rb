# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::NamingStrategies do
  describe 'identity' do
    it 'returns the same property name' do
      property_name = SecureRandom.uuid.to_sym
      expect(EasyTalk::NamingStrategies::IDENTITY.call(property_name)).to eq(property_name)
    end
  end

  describe 'snake_case' do
    it 'converts camelCase to snake_case' do
      expect(EasyTalk::NamingStrategies::SNAKE_CASE.call(:camelCase)).to eq(:camel_case)
    end

    it 'converts PascalCase to snake_case' do
      expect(EasyTalk::NamingStrategies::SNAKE_CASE.call(:PascalCase)).to eq(:pascal_case)
    end

    it 'leaves snake_case unchanged' do
      expect(EasyTalk::NamingStrategies::SNAKE_CASE.call(:snake_case)).to eq(:snake_case)
    end
  end

  describe 'camelCase' do
    it 'converts snake_case to camelCase' do
      expect(EasyTalk::NamingStrategies::CAMEL_CASE.call(:snake_case)).to eq(:snakeCase)
    end

    it 'converts kebab-case to camelCase' do
      expect(EasyTalk::NamingStrategies::CAMEL_CASE.call(:'kebab-case')).to eq(:kebabCase)
    end

    it 'leaves camelCase unchanged' do
      expect(EasyTalk::NamingStrategies::CAMEL_CASE.call(:camelCase)).to eq(:camelCase)
    end
  end

  describe 'PascalCase' do
    it 'converts snake_case to PascalCase' do
      expect(EasyTalk::NamingStrategies::PASCAL_CASE.call(:snake_case)).to eq(:SnakeCase)
    end

    it 'converts kebab-case to PascalCase' do
      expect(EasyTalk::NamingStrategies::PASCAL_CASE.call(:'kebab-case')).to eq(:KebabCase)
    end

    it 'converts camelCase to PascalCase' do
      expect(EasyTalk::NamingStrategies::PASCAL_CASE.call(:camelCase)).to eq(:CamelCase)
    end
  end

  describe '.derive_strategy' do
    context 'with symbol strategies' do
      it 'returns IDENTITY strategy for :identity' do
        strategy = described_class.derive_strategy(:identity)
        expect(strategy).to eq(EasyTalk::NamingStrategies::IDENTITY)
      end

      it 'returns SNAKE_CASE strategy for :snake_case' do
        strategy = described_class.derive_strategy(:snake_case)
        expect(strategy).to eq(EasyTalk::NamingStrategies::SNAKE_CASE)
      end

      it 'returns CAMEL_CASE strategy for :camel_case' do
        strategy = described_class.derive_strategy(:camel_case)
        expect(strategy).to eq(EasyTalk::NamingStrategies::CAMEL_CASE)
      end

      it 'returns PASCAL_CASE strategy for :pascal_case' do
        strategy = described_class.derive_strategy(:pascal_case)
        expect(strategy).to eq(EasyTalk::NamingStrategies::PASCAL_CASE)
      end

      it 'raises NameError for unknown symbol strategy' do
        expect do
          described_class.derive_strategy(:unknown_strategy)
        end.to raise_error(NameError)
      end
    end

    context 'with Proc strategies' do
      it 'returns the provided proc unchanged' do
        custom_proc = ->(name) { name.to_s.reverse.to_sym }
        strategy = described_class.derive_strategy(custom_proc)
        expect(strategy).to eq(custom_proc)
      end

      it 'allows custom transformations' do
        custom_proc = ->(name) { name.to_s.upcase.to_sym }
        strategy = described_class.derive_strategy(custom_proc)
        expect(strategy.call(:hello)).to eq(:HELLO)
      end
    end

    context 'with invalid strategy type' do
      it 'raises TypeError for string' do
        expect do
          described_class.derive_strategy('identity')
        end.to raise_error(TypeError)
      end

      it 'raises TypeError for integer' do
        expect do
          described_class.derive_strategy(123)
        end.to raise_error(TypeError)
      end

      it 'raises TypeError for array' do
        expect do
          described_class.derive_strategy([:identity])
        end.to raise_error(TypeError)
      end
    end
  end
end
