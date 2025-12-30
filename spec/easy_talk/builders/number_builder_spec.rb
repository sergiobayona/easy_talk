# frozen_string_literal: true

require 'spec_helper'
require 'easy_talk/builders/number_builder'

RSpec.describe EasyTalk::Builders::NumberBuilder do
  describe '#initialize' do
    let(:builder) { described_class.new(:age, minimum: 18, maximum: 100) }

    it 'sets the name' do
      expect(builder.property_name).to eq(:age)
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

      it 'supports float values for minimum' do
        prop = described_class.new(:price, minimum: 0.01).build
        expect(prop).to eq({ type: 'number', minimum: 0.01 })
      end

      it 'supports float values for maximum' do
        prop = described_class.new(:price, maximum: 99.99).build
        expect(prop).to eq({ type: 'number', maximum: 99.99 })
      end

      it 'supports negative numbers' do
        prop = described_class.new(:temperature, minimum: -40, maximum: 50).build
        expect(prop).to eq({ type: 'number', minimum: -40, maximum: 50 })
      end

      it 'combines multiple constraints' do
        prop = described_class.new(:score,
                                   minimum: 0,
                                   maximum: 100,
                                   multiple_of: 0.5,
                                   description: 'Test score').build
        expect(prop).to eq({
                             type: 'number',
                             minimum: 0,
                             maximum: 100,
                             multipleOf: 0.5,
                             description: 'Test score'
                           })
      end
    end

    context 'with invalid configurations' do
      it 'raises error for unknown options' do
        expect do
          described_class.new(:value, invalid_option: 'value').build
        end.to raise_error(EasyTalk::UnknownOptionError, /Unknown option 'invalid_option'/)
      end

      it 'raises error when minimum is not a number' do
        expect do
          described_class.new(:value, minimum: '10').build
        end.to raise_error(EasyTalk::ConstraintError, /Constraint 'minimum' expects/)
      end

      it 'raises error when maximum is not a number' do
        expect do
          described_class.new(:value, maximum: '100').build
        end.to raise_error(EasyTalk::ConstraintError, /Constraint 'maximum' expects/)
      end

      it 'raises error when multiple_of is not a number' do
        expect do
          described_class.new(:value, multiple_of: '2').build
        end.to raise_error(EasyTalk::ConstraintError, /Constraint 'multiple_of' expects/)
      end

      it 'raises error when exclusive_minimum is not a number' do
        expect do
          described_class.new(:value, exclusive_minimum: '10').build
        end.to raise_error(EasyTalk::ConstraintError, /Constraint 'exclusive_minimum' expects/)
      end

      it 'raises error when exclusive_maximum is not a number' do
        expect do
          described_class.new(:value, exclusive_maximum: '100').build
        end.to raise_error(EasyTalk::ConstraintError, /Constraint 'exclusive_maximum' expects/)
      end

      it 'raises error when const is not a number' do
        expect do
          described_class.new(:value, const: 'ten').build
        end.to raise_error(EasyTalk::ConstraintError, /Constraint 'const' expects/)
      end

      it 'raises error when default is not a number' do
        expect do
          described_class.new(:value, default: 'zero').build
        end.to raise_error(EasyTalk::ConstraintError, /Constraint 'default' expects/)
      end

      it 'raises error when enum is not an array' do
        expect do
          described_class.new(:value, enum: 123).build
        end.to raise_error(EasyTalk::ConstraintError)
      end
    end

    context 'with nil values' do
      it 'excludes constraints with nil values' do
        prop = described_class.new(:value,
                                   minimum: nil,
                                   maximum: nil,
                                   multiple_of: nil).build
        expect(prop).to eq({ type: 'number' })
      end

      it 'excludes only nil constraints, keeping valid ones' do
        prop = described_class.new(:value,
                                   minimum: 0,
                                   maximum: nil,
                                   description: 'Test').build
        expect(prop).to eq({ type: 'number', minimum: 0, description: 'Test' })
      end
    end

    context 'with optional flag' do
      it 'includes optional flag when true' do
        prop = described_class.new(:value, optional: true).build
        expect(prop).to eq({ type: 'number', optional: true })
      end

      it 'includes optional flag when false' do
        prop = described_class.new(:value, optional: false).build
        expect(prop).to eq({ type: 'number', optional: false })
      end
    end
  end

  describe '.collection_type?' do
    it 'returns false since number is not a collection type' do
      expect(described_class.collection_type?).to be false
    end
  end
end
