# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::ErrorFormatter::ErrorCodeMapper do
  describe '.map' do
    it 'maps :blank to "blank"' do
      expect(described_class.map(:blank)).to eq('blank')
    end

    it 'maps :invalid to "invalid_format"' do
      expect(described_class.map(:invalid)).to eq('invalid_format')
    end

    it 'maps :too_short to "too_short"' do
      expect(described_class.map(:too_short)).to eq('too_short')
    end

    it 'maps :too_long to "too_long"' do
      expect(described_class.map(:too_long)).to eq('too_long')
    end

    it 'maps :greater_than to "too_small"' do
      expect(described_class.map(:greater_than)).to eq('too_small')
    end

    it 'maps :less_than to "too_large"' do
      expect(described_class.map(:less_than)).to eq('too_large')
    end

    it 'maps :inclusion to "not_included"' do
      expect(described_class.map(:inclusion)).to eq('not_included')
    end

    it 'returns the error type as string for unknown types' do
      expect(described_class.map(:custom_error)).to eq('custom_error')
    end

    it 'accepts string input' do
      expect(described_class.map('blank')).to eq('blank')
    end
  end

  describe '.code_from_detail' do
    it 'extracts code from detail hash' do
      detail = { error: :blank }
      expect(described_class.code_from_detail(detail)).to eq('blank')
    end

    it 'extracts code from detail with additional options' do
      detail = { error: :too_short, count: 2 }
      expect(described_class.code_from_detail(detail)).to eq('too_short')
    end

    it 'returns "unknown" for nil error key' do
      detail = {}
      expect(described_class.code_from_detail(detail)).to eq('unknown')
    end
  end
end
