# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EsquemaBase::Builders::IntegerBuilder do
  context 'with valid options' do
    it 'returns a bare json object' do
      prop = described_class.new('name').build
      expect(prop).to eq({ type: 'integer' })
    end

    it 'includes a title' do
      prop = described_class.new('name', title: 'Title').build
      expect(prop).to eq({ title: 'Title', type: 'integer' })
    end

    it 'includes a description' do
      prop = described_class.new('name', description: 'Description').build
      expect(prop).to eq({ description: 'Description', type: 'integer' })
    end

    it 'includes the minimum' do
      prop = described_class.new('name', minimum: 1).build
      expect(prop).to eq({ type: 'integer', minimum: 1 })
    end

    it 'includes the maximum' do
      prop = described_class.new('name', maximum: 10).build
      expect(prop).to eq({ type: 'integer', maximum: 10 })
    end

    it 'includes the exclusiveMinimum' do
      prop = described_class.new('name', exclusive_minimum: 1).build
      expect(prop).to eq({ type: 'integer', exclusiveMinimum: 1 })
    end

    it 'includes the exclusiveMaximum' do
      prop = described_class.new('name', exclusive_maximum: 10).build
      expect(prop).to eq({ type: 'integer', exclusiveMaximum: 10 })
    end

    it 'includes the multipleOf' do
      prop = described_class.new('name', multiple_of: 2).build
      expect(prop).to eq({ type: 'integer', multipleOf: 2 })
    end

    it 'includes the enum' do
      prop = described_class.new('name', enum: [1, 2, 3]).build
      expect(prop).to eq({ type: 'integer', enum: [1, 2, 3] })
    end

    it 'includes the const' do
      prop = described_class.new('name', const: 1).build
      expect(prop).to eq({ type: 'integer', const: 1 })
    end

    it 'includes the default' do
      prop = described_class.new('name', default: 1).build
      expect(prop).to eq({ type: 'integer', default: 1 })
    end
  end

  context 'with invalid options' do
    it 'raises an error' do
      expect do
        described_class.new('name', invalid: 'option').build
      end.to raise_error(ArgumentError)
    end
  end

  context 'with invalid option values' do
    it 'raises an error' do
      expect do
        described_class.new('name', minimum: '1').build
      end.to raise_error(TypeError)
    end

    it 'raises an error' do
      expect do
        described_class.new('name', maximum: '10').build
      end.to raise_error(TypeError)
    end

    context 'with nil value' do
      it 'raises an error with nil value' do
        prop = described_class.new('name', minimum: nil).build
        expect(prop).to eq({ type: 'integer' })
      end
    end
  end
end
