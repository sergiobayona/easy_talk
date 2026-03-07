# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::Builders::NullBuilder do
  describe '#build' do
    context 'with basic configuration' do
      it 'returns type null with no options' do
        builder = described_class.new(:value)
        expect(builder.build).to eq({ type: 'null' })
      end

      it 'rejects unknown constraints' do
        expect do
          described_class.new(:value, { some_option: 'ignored' })
        end.to raise_error(EasyTalk::UnknownOptionError, /Unknown option 'some_option'/)
      end
    end

    context 'with empty constraints hash' do
      it 'returns type null' do
        builder = described_class.new(:value, {})
        expect(builder.build).to eq({ type: 'null' })
      end
    end

    context 'with common options' do
      %i[title description optional].each do |option|
        it "accepts the '#{option}' option" do
          value = option == :optional ? true : "test #{option}"
          expect do
            described_class.new(:value, { option => value })
          end.not_to raise_error
        end
      end
    end

    context 'with invalid options' do
      {
        minimum: 0,
        maximum: 100,
        min_length: 1,
        max_length: 10,
        format: 'email',
        pattern: '^[a-z]+$',
        enum: [nil],
        const: nil,
        default: nil
      }.each do |option, value|
        it "rejects the '#{option}' option with UnknownOptionError" do
          expect do
            described_class.new(:value, { option => value })
          end.to raise_error(EasyTalk::UnknownOptionError, /Unknown option '#{option}'/)
        end
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
