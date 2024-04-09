# frozen_string_literal: true

require 'spec_helper'
require 'easy_talk/builders/number_builder'

RSpec.describe EasyTalk::Builders::NumberBuilder do
  describe '#initialize' do
    it 'sets the name and options' do
      builder = described_class.new(:age, nil, minimum: 18, maximum: 100)
      expect(builder.name).to eq(:age)
      expect(builder.options).to eq({ minimum: 18, maximum: 100 })
    end
  end

  describe '#build' do
    context 'with valid options' do
      it 'returns a bare json object' do
        prop = described_class.new(:age).build
        expect(prop).to eq({ type: 'number' })
      end

      it 'includes a title' do
        prop = described_class.new(:age, nil, title: 'Title').build
        expect(prop).to eq({ title: 'Title', type: 'number' })
      end

      it 'includes a description' do
        prop = described_class.new(:age, nil, description: 'Description').build
        expect(prop).to eq({ description: 'Description', type: 'number' })
      end

      it 'includes the multipleOf' do
        prop = described_class.new(:age, nil, multiple_of: 2).build
        expect(prop).to eq({ type: 'number', multipleOf: 2 })
      end

      it 'includes the minimum' do
        prop = described_class.new(:age, nil, minimum: 18).build
        expect(prop).to eq({ type: 'number', minimum: 18 })
      end

      it 'includes the maximum' do
        prop = described_class.new(:age, nil, maximum: 100).build
        expect(prop).to eq({ type: 'number', maximum: 100 })
      end

      it 'includes the exclusiveMinimum' do
        prop = described_class.new(:age, nil, exclusive_minimum: 18).build
        expect(prop).to eq({ type: 'number', exclusiveMinimum: 18 })
      end

      it 'includes the exclusiveMaximum' do
        prop = described_class.new(:age, nil, exclusive_maximum: 100).build
        expect(prop).to eq({ type: 'number', exclusiveMaximum: 100 })
      end

      it 'includes the enum' do
        prop = described_class.new(:age, nil, enum: [18, 21, 65]).build
        expect(prop).to eq({ type: 'number', enum: [18, 21, 65] })
      end

      it 'includes the const' do
        prop = described_class.new(:age, nil, const: 18).build
        expect(prop).to eq({ type: 'number', const: 18 })
      end

      it 'includes the default' do
        prop = described_class.new(:age, nil, default: 18).build
        expect(prop).to eq({ type: 'number', default: 18 })
      end

      it 'does not include the optional' do
        prop = described_class.new(:age).build
        expect(prop).to eq({ type: 'number' })
      end
    end
  end
end
