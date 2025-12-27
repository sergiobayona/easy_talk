# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::ErrorFormatter::Base do
  let(:test_class) do
    Class.new do
      include EasyTalk::Model

      def self.name = 'BaseFormatterTest'

      define_schema do
        property :name, String
      end
    end
  end

  describe '#format' do
    it 'raises NotImplementedError' do
      instance = test_class.new(name: nil)
      instance.valid?

      formatter = described_class.new(instance.errors)

      expect { formatter.format }.to raise_error(
        NotImplementedError,
        'EasyTalk::ErrorFormatter::Base must implement #format'
      )
    end
  end

  describe '#error_entries' do
    it 'builds normalized error entries' do
      instance = test_class.new(name: nil)
      instance.valid?

      formatter = described_class.new(instance.errors)
      entries = formatter.send(:error_entries)

      expect(entries).to be_an(Array)
      expect(entries.first).to include(
        attribute: :name,
        message: a_kind_of(String),
        full_message: a_kind_of(String),
        type: a_kind_of(Symbol)
      )
    end
  end

  describe '#include_codes?' do
    context 'when include_codes option is set' do
      it 'returns the option value' do
        instance = test_class.new
        formatter = described_class.new(instance.errors, include_codes: false)
        expect(formatter.send(:include_codes?)).to be false

        formatter = described_class.new(instance.errors, include_codes: true)
        expect(formatter.send(:include_codes?)).to be true
      end
    end

    context 'when include_codes option is not set' do
      it 'returns the config value' do
        original = EasyTalk.configuration.include_error_codes

        EasyTalk.configuration.include_error_codes = false
        instance = test_class.new
        formatter = described_class.new(instance.errors)
        expect(formatter.send(:include_codes?)).to be false

        EasyTalk.configuration.include_error_codes = original
      end
    end
  end
end
