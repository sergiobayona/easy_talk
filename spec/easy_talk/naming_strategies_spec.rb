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
end
