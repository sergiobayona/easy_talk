# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::ValidationAdapters::Base do
  let(:test_class) do
    Class.new do
      include EasyTalk::Model

      def self.name = 'TestModel'
    end
  end

  describe '.build_validations' do
    it 'creates an instance and calls apply_validations' do
      adapter = described_class.new(test_class, :name, String, {})
      expect { adapter.apply_validations }.to raise_error(NotImplementedError)
    end
  end

  describe '#apply_validations' do
    it 'raises NotImplementedError' do
      adapter = described_class.new(test_class, :name, String, {})
      expect { adapter.apply_validations }.to raise_error(
        NotImplementedError,
        'EasyTalk::ValidationAdapters::Base must implement #apply_validations'
      )
    end
  end

  describe '#optional?' do
    context 'when optional: true in constraints' do
      it 'returns true' do
        adapter = described_class.new(test_class, :name, String, { optional: true })
        expect(adapter.send(:optional?)).to be true
      end
    end

    context 'when optional: false in constraints' do
      it 'returns false' do
        adapter = described_class.new(test_class, :name, String, { optional: false })
        expect(adapter.send(:optional?)).to be false
      end
    end

    context 'when no optional constraint' do
      it 'returns false' do
        adapter = described_class.new(test_class, :name, String, {})
        expect(adapter.send(:optional?)).to be false
      end
    end

    context 'with nilable type and nilable_is_optional config' do
      before do
        EasyTalk.configuration.nilable_is_optional = true
      end

      after do
        EasyTalk.configuration.nilable_is_optional = false
      end

      it 'returns true for nilable type' do
        nilable_type = T.nilable(String)
        adapter = described_class.new(test_class, :name, nilable_type, {})
        expect(adapter.send(:optional?)).to be true
      end
    end
  end

  describe '#nilable_type?' do
    it 'returns true for T.nilable types' do
      nilable_type = T.nilable(String)
      adapter = described_class.new(test_class, :name, nilable_type, {})
      expect(adapter.send(:nilable_type?)).to be true
    end

    it 'returns false for non-nilable types' do
      adapter = described_class.new(test_class, :name, String, {})
      expect(adapter.send(:nilable_type?)).to be false
    end
  end

  describe '#get_type_class' do
    it 'returns the class for a Class type' do
      adapter = described_class.new(test_class, :name, String, {})
      expect(adapter.send(:get_type_class, String)).to eq(String)
    end

    it 'returns Array for T::Array types' do
      typed_array = T::Array[String]
      adapter = described_class.new(test_class, :items, typed_array, {})
      expect(adapter.send(:get_type_class, typed_array)).to eq(Array)
    end

    it 'returns [TrueClass, FalseClass] for T::Boolean' do
      boolean_type = T::Boolean
      adapter = described_class.new(test_class, :active, boolean_type, {})
      expect(adapter.send(:get_type_class, boolean_type)).to eq([TrueClass, FalseClass])
    end
  end
end
