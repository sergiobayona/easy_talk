# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::ErrorFormatter::PathConverter do
  describe '.to_json_pointer' do
    it 'converts simple attribute to JSON Pointer' do
      expect(described_class.to_json_pointer(:name)).to eq('/properties/name')
    end

    it 'converts nested attribute to JSON Pointer' do
      expect(described_class.to_json_pointer('email.address')).to eq('/properties/email/properties/address')
    end

    it 'converts deeply nested attribute to JSON Pointer' do
      result = described_class.to_json_pointer('user.profile.settings.theme')
      expect(result).to eq('/properties/user/properties/profile/properties/settings/properties/theme')
    end

    it 'accepts symbol input' do
      expect(described_class.to_json_pointer(:'email.address')).to eq('/properties/email/properties/address')
    end
  end

  describe '.to_jsonapi_pointer' do
    it 'converts simple attribute to JSON:API pointer' do
      expect(described_class.to_jsonapi_pointer(:name)).to eq('/data/attributes/name')
    end

    it 'converts nested attribute to JSON:API pointer' do
      expect(described_class.to_jsonapi_pointer('email.address')).to eq('/data/attributes/email/address')
    end

    it 'uses custom prefix' do
      result = described_class.to_jsonapi_pointer(:name, prefix: '/data')
      expect(result).to eq('/data/name')
    end
  end

  describe '.to_flat' do
    it 'returns attribute as string' do
      expect(described_class.to_flat(:name)).to eq('name')
    end

    it 'preserves dot notation' do
      expect(described_class.to_flat('email.address')).to eq('email.address')
    end
  end
end
