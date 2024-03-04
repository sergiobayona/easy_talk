# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EsquemaBase::Builders::ArrayBuilder do
  context 'with valid options' do
    context 'with a string inner type' do
      it 'returns a basic json object' do
        prop = described_class.new('name', String).build_property
        expect(prop).to eq({ type: 'array', items: { type: 'string' } })
      end

      it 'includes a title' do
        prop = described_class.new('name', String, title: 'Title').build_property
        expect(prop).to eq({ title: 'Title', type: 'array', items: { type: 'string' } })
      end

      it 'includes a description' do
        prop = described_class.new('name', String, description: 'Description').build_property
        expect(prop).to eq({ description: 'Description', type: 'array', items: { type: 'string' } })
      end

      it 'includes the minItems' do
        prop = described_class.new('name', String, min_items: 1).build_property
        expect(prop).to eq({ type: 'array', minItems: 1, items: { type: 'string' } })
      end

      it 'includes the maxItems' do
        prop = described_class.new('name', String, max_items: 10).build_property
        expect(prop).to eq({ type: 'array', maxItems: 10, items: { type: 'string' } })
      end

      it 'includes the uniqueItems' do
        prop = described_class.new('name', String, unique_items: true).build_property
        expect(prop).to eq({ type: 'array', uniqueItems: true, items: { type: 'string' } })
      end

      it 'includes the enum' do
        prop = described_class.new('name', String, enum: %w[one two three]).build_property
        expect(prop).to eq({ type: 'array', enum: %w[one two three], items: { type: 'string' } })
      end

      it 'includes the const' do
        prop = described_class.new('name', String, const: %w[one]).build_property
        expect(prop).to eq({ type: 'array', const: %w[one], items: { type: 'string' } })
      end
    end

    context 'with an integer inner type' do
      it 'returns a basic json object' do
        prop = described_class.new('name', Integer).build_property
        expect(prop).to eq({ type: 'array', items: { type: 'integer' } })
      end

      it 'includes a title' do
        prop = described_class.new('name', Integer, title: 'Title').build_property
        expect(prop).to eq({ title: 'Title', type: 'array', items: { type: 'integer' } })
      end

      it 'includes a description' do
        prop = described_class.new('name', Integer, description: 'Description').build_property
        expect(prop).to eq({ description: 'Description', type: 'array', items: { type: 'integer' } })
      end

      it 'includes the minItems' do
        prop = described_class.new('name', Integer, min_items: 1).build_property
        expect(prop).to eq({ type: 'array', minItems: 1, items: { type: 'integer' } })
      end

      it 'includes the maxItems' do
        prop = described_class.new('name', Integer, max_items: 10).build_property
        expect(prop).to eq({ type: 'array', maxItems: 10, items: { type: 'integer' } })
      end

      it 'includes the uniqueItems' do
        prop = described_class.new('name', Integer, unique_items: true).build_property
        expect(prop).to eq({ type: 'array', uniqueItems: true, items: { type: 'integer' } })
      end

      it 'includes the enum' do
        prop = described_class.new('name', Integer, enum: [1, 2, 3]).build_property
        expect(prop).to eq({ type: 'array', enum: [1, 2, 3], items: { type: 'integer' } })
      end

      it 'includes the const' do
        prop = described_class.new('name', Integer, const: [1]).build_property
        expect(prop).to eq({ type: 'array', const: [1], items: { type: 'integer' } })
      end
    end
  end

  context 'with invalid keys' do
    it 'raises an error' do
      expect do
        described_class.new('name', String, invalid: 'key').build_property
      end.to raise_error(ArgumentError,
                         'Unknown key: :invalid. Valid keys are: :title, :description, :optional, :min_items, :max_items, :unique_items, :enum, :const')
    end
  end
end
