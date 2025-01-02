# frozen_string_literal: true

require 'spec_helper'
require 'easy_talk/builders/number_builder'

RSpec.describe EasyTalk::Builders::NumberBuilder do
  describe '#initialize' do
    let(:builder) { described_class.new(:age, minimum: 18, maximum: 100) }

    it 'sets the name' do
      expect(builder.name).to eq(:age)
    end

    it 'sets the constraint options' do
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
        prop = described_class.new(:age, title: 'Title').build
        expect(prop).to eq({ title: 'Title', type: 'number' })
      end

      it 'includes a description' do
        prop = described_class.new(:age, description: 'Description').build
        expect(prop).to eq({ description: 'Description', type: 'number' })
      end

      it 'includes the multipleOf' do
        prop = described_class.new(:age, multiple_of: 2).build
        expect(prop).to eq({ type: 'number', multipleOf: 2 })
      end

      it 'includes the minimum' do
        prop = described_class.new(:age, minimum: 18).build
        expect(prop).to eq({ type: 'number', minimum: 18 })
      end

      it 'includes the maximum' do
        prop = described_class.new(:age, maximum: 100).build
        expect(prop).to eq({ type: 'number', maximum: 100 })
      end

      it 'includes the exclusiveMinimum' do
        prop = described_class.new(:age, exclusive_minimum: 18).build
        expect(prop).to eq({ type: 'number', exclusiveMinimum: 18 })
      end

      it 'includes the exclusiveMaximum' do
        prop = described_class.new(:age, exclusive_maximum: 100).build
        expect(prop).to eq({ type: 'number', exclusiveMaximum: 100 })
      end

      it 'includes the enum' do
        prop = described_class.new(:age, enum: [18, 21, 65]).build
        expect(prop).to eq({ type: 'number', enum: [18, 21, 65] })
      end

      it 'includes the const' do
        prop = described_class.new(:age, const: 18).build
        expect(prop).to eq({ type: 'number', const: 18 })
      end

      it 'includes the default' do
        prop = described_class.new(:age, default: 18).build
        expect(prop).to eq({ type: 'number', default: 18 })
      end
    end
  end
end
