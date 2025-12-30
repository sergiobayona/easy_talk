# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::Builders::NullBuilder do
  describe '#build' do
    context 'with basic configuration' do
      it 'returns type null with no options' do
        builder = described_class.new(:value)
        expect(builder.build).to eq({ type: 'null' })
      end

      it 'returns type null when constraints are provided' do
        # NullBuilder ignores constraints since null type has no constraints
        builder = described_class.new(:value, { some_option: 'ignored' })
        expect(builder.build).to eq({ type: 'null' })
      end
    end

    context 'with empty constraints hash' do
      it 'returns type null' do
        builder = described_class.new(:value, {})
        expect(builder.build).to eq({ type: 'null' })
      end
    end

    context 'with property naming' do
      it 'stores the property name correctly' do
        builder = described_class.new(:my_null_field)
        expect(builder.property_name).to eq(:my_null_field)
      end
    end

    context 'with schema structure' do
      it 'has correct schema attribute' do
        builder = described_class.new(:value)
        expect(builder.schema).to eq({ type: 'null' })
      end
    end
  end

  describe '.collection_type?' do
    it 'returns false since null is not a collection type' do
      expect(described_class.collection_type?).to be false
    end
  end
end
