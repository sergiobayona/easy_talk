# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EsquemaBase::Builders::StringBuilder do
  context 'with valid options' do
    it 'returns a bare json object' do
      prop = described_class.new('name').build_property
      expect(prop).to eq({ type: 'string' })
    end

    it 'includes a title' do
      prop = described_class.new('name', title: 'Title').build_property
      expect(prop).to eq({ title: 'Title', type: 'string' })
    end

    it 'includes a description' do
      prop = described_class.new('name', description: 'Description').build_property
      expect(prop).to eq({ description: 'Description', type: 'string' })
    end

    it 'includes the format' do
      prop = described_class.new('name', format: 'email').build_property
      expect(prop).to eq({ type: 'string', format: 'email' })
    end

    it 'includes the pattern' do
      prop = described_class.new('name', pattern: '^[a-zA-Z]+$').build_property
      expect(prop).to eq({ type: 'string', pattern: '^[a-zA-Z]+$' })
    end

    it 'includes the minLength' do
      prop = described_class.new('name', min_length: 1).build_property
      expect(prop).to eq({ type: 'string', minLength: 1 })
    end

    it 'includes the maxLength' do
      prop = described_class.new('name', max_length: 10).build_property
      expect(prop).to eq({ type: 'string', maxLength: 10 })
    end

    it 'includes the enum' do
      prop = described_class.new('name', enum: %w[one two three]).build_property
      expect(prop).to eq({ type: 'string', enum: %w[one two three] })
    end

    it 'includes the const' do
      prop = described_class.new('name', const: 'one').build_property
      expect(prop).to eq({ type: 'string', const: 'one' })
    end

    it 'includes the default' do
      prop = described_class.new('name', default: 'default').build_property
      expect(prop).to eq({ type: 'string', default: 'default' })
    end
  end

  context 'with invalid keys' do
    it 'raises an error' do
      error_msg = 'Unknown key: :invalid. Valid keys are: :title, :description, :format, :pattern, :min_length, :max_length, :enum, :const, :default'
      expect do
        described_class.new('name', invalid: 'invalid').build_property
      end.to raise_error(ArgumentError, error_msg)
    end
  end

  context 'with invalid values' do
    it 'raises an error' do
      expect do
        described_class.new('name', min_length: 'invalid').build_property
      end.to raise_error(TypeError)
    end
  end

  context 'with empty string value' do
    it 'raises a type error' do
      expect do
        described_class.new('name', min_length: '').build_property
      end.to raise_error(TypeError)
    end
  end

  context 'with nil value' do
    it 'does not include the key' do
      prop = described_class.new('name', min_length: nil).build_property
      expect(prop).to eq({ type: 'string' })
    end
  end
end
