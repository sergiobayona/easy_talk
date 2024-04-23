# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::Builders::TypedArrayBuilder do
  context 'with valid options' do
    context 'with a string inner type' do
      it 'returns a basic json object' do
        prop = described_class.new(:name, T::Array[String]).build
        expect(prop).to eq({ type: 'array', items: { type: 'string' } })
      end

      it 'includes a title' do
        prop = described_class.new(:name, T::Array[String], title: 'Title').build
        expect(prop).to eq({ title: 'Title', type: 'array', items: { type: 'string' } })
      end

      it 'includes a description' do
        prop = described_class.new(:name, T::Array[String], description: 'Description').build
        expect(prop).to eq({ description: 'Description', type: 'array', items: { type: 'string' } })
      end

      it 'includes the minItems' do
        prop = described_class.new(:name, T::Array[String], min_items: 1).build
        expect(prop).to eq({ type: 'array', minItems: 1, items: { type: 'string' } })
      end

      it 'includes the maxItems' do
        prop = described_class.new(:name, T::Array[String], max_items: 10).build
        expect(prop).to eq({ type: 'array', maxItems: 10, items: { type: 'string' } })
      end

      it 'includes the uniqueItems' do
        prop = described_class.new(:name, T::Array[String], unique_items: true).build
        expect(prop).to eq({ type: 'array', uniqueItems: true, items: { type: 'string' } })
      end

      it 'includes the enum' do
        prop = described_class.new(:name, T::Array[String], enum: %w[one two three]).build
        expect(prop).to eq({ type: 'array', enum: %w[one two three], items: { type: 'string' } })
      end

      it 'includes the const' do
        prop = described_class.new(:name, T::Array[String], const: %w[one]).build
        expect(prop).to eq({ type: 'array', const: %w[one], items: { type: 'string' } })
      end

      pending 'with an invalid constraint value' do
        pending 'raises an error' do # unclear why this does not throw an error
          expect do
            described_class.new(:name, T::Array[String], enum: [1, 2, 3]).build
          end.to raise_error(TypeError)
        end
      end
    end

    context 'with an integer inner type' do
      it 'returns a basic json object' do
        prop = described_class.new(:name, T::Array[Integer]).build
        expect(prop).to eq({ type: 'array', items: { type: 'integer' } })
      end

      it 'includes a title' do
        prop = described_class.new(:name, T::Array[Integer], title: 'Title').build
        expect(prop).to eq({ title: 'Title', type: 'array', items: { type: 'integer' } })
      end

      it 'includes a description' do
        prop = described_class.new(:name, T::Array[Integer], description: 'Description').build
        expect(prop).to eq({ description: 'Description', type: 'array', items: { type: 'integer' } })
      end

      it 'includes the minItems' do
        prop = described_class.new(:name, T::Array[Integer], min_items: 1).build
        expect(prop).to eq({ type: 'array', minItems: 1, items: { type: 'integer' } })
      end

      it 'includes the maxItems' do
        prop = described_class.new(:name, T::Array[Integer], max_items: 10).build
        expect(prop).to eq({ type: 'array', maxItems: 10, items: { type: 'integer' } })
      end

      it 'includes the uniqueItems' do
        prop = described_class.new(:name, T::Array[Integer], unique_items: true).build
        expect(prop).to eq({ type: 'array', uniqueItems: true, items: { type: 'integer' } })
      end

      it 'includes the enum' do
        prop = described_class.new(:name, T::Array[Integer], enum: [1, 2, 3]).build
        expect(prop).to eq({ type: 'array', enum: [1, 2, 3], items: { type: 'integer' } })
      end

      it 'includes the const' do
        prop = described_class.new(:name, T::Array[Integer], const: [1]).build
        expect(prop).to eq({ type: 'array', const: [1], items: { type: 'integer' } })
      end
    end
  end

  context 'with invalid keys' do
    it 'raises an error' do
      expect do
        described_class.new(:name, String, invalid: 'key').build
      end.to raise_error(ArgumentError,
                         'Unknown key: :invalid. Valid keys are: :title, :description, :min_items, :max_items, :unique_items, :enum, :const')
    end
  end

  context 'with invalid constraint value' do
    it 'raises an error' do
      expect do
        described_class.new(:name, T::Array[Integer], enum: %w[one two three]).build
      end.to raise_error(TypeError, 'Invalid type for enum')
    end
  end
end
