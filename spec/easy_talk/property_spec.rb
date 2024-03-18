# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::Property do
  it 'returns a string schema' do
    prop = described_class.new(:name, String).build
    expect(prop).to eq(type: 'string')
  end

  it 'returns an integer schema' do
    prop = described_class.new(:name, Integer).build
    expect(prop).to eq(type: 'integer')
  end

  it 'returns a number schema' do
    prop = described_class.new(:name, Float).build
    expect(prop).to eq(type: 'number')
  end

  it 'returns a boolean schema' do
    prop = described_class.new(:name, T::Boolean).build
    expect(prop).to eq(type: 'boolean')
  end

  it 'returns a null schema' do
    prop = described_class.new(:name, NilClass).build
    expect(prop).to eq(type: 'null')
  end

  it 'returns an array of strings schema' do
    prop = described_class.new(:name, T::Array[String]).build
    expect(prop).to eq(type: 'array', items: { type: 'string' })
  end

  it 'returns an array of integers schema' do
    prop = described_class.new(:name, T::Array[Integer]).build
    expect(prop).to eq(type: 'array', items: { type: 'integer' })
  end

  it 'returns a date schema' do
    prop = described_class.new(:name, Date).build
    expect(prop).to eq(type: 'string', format: 'date')
  end

  it 'returns a date-time schema' do
    prop = described_class.new(:name, DateTime).build
    expect(prop).to eq(type: 'string', format: 'date-time')
  end

  it 'returns a time schema' do
    prop = described_class.new(:name, Time).build
    expect(prop).to eq(type: 'string', format: 'time')
  end

  describe 'with a union type' do
    prop = described_class.new(:name, T.any(Integer, String)).build
    it "returns a schema with 'anyOf' property" do
      expect(prop.keys).to include(:anyOf)
      expect(prop[:anyOf].size).to eq(2)
      expect(prop[:anyOf].first).to be_a(EasyTalk::Property)
      expect(prop[:anyOf].first.type).to be_a(T::Types::Simple)
      expect(prop[:anyOf].first.type.raw_type).to eq(Integer)
    end
  end

  describe 'with missing type' do
    it 'raises an error' do
      expect { described_class.new(:name).build }.to raise_error(ArgumentError, 'property type is missing')
    end

    it 'raises an error when type is not supported' do
      expect { described_class.new(:name, Something) }.to raise_error(NameError, 'uninitialized constant Something')
    end

    it 'raises an error when type is empty' do
      expect do
        described_class.new(:name, '').build
      end.to raise_error(ArgumentError, 'property type is missing')
    end

    it 'raises an error when type is nil' do
      expect do
        described_class.new(:name, nil).build
      end.to raise_error(ArgumentError, 'property type is missing')
    end

    it 'raises an error when type is blank' do
      expect do
        described_class.new(:name, ' ').build
      end.to raise_error(ArgumentError, 'property type is missing')
    end

    it 'raises an error when type is an empty array' do
      expect do
        described_class.new(:name, []).build
      end.to raise_error(ArgumentError, 'property type is missing')
    end
  end

  context 'array with simple class schema' do
    class CustomClass; end

    it 'returns an array of custom class type' do
      prop = described_class.new(:name, T::Array[CustomClass]).build
      expect(prop).to eq(type: 'array', items: { type: 'object' })
    end
  end

  context 'array with custom class that has a schema defined' do
    let(:user) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'User'
        end

        define_schema do
          property :name, String
          property :email, String, format: 'email'
          property :age, Integer
        end
      end
    end
  end

  # it 'returns an object type' do
  #   prop = described_class.new(:name, T::Hash[Symbol, String]).build
  #   expect(prop).to eq(type: 'object')
  # end

  # it 'raises an error when type is not supported' do
  #   expect { described_class.new(:name, Object).build }.to raise_error('Type Object not supported')
  # end
  #
  context 'as_json' do
    it 'returns a json schema' do
      prop = described_class.new(:name, String).as_json
      expect(prop).to include_json(type: 'string')
    end

    it 'returns a json schema with options' do
      prop = described_class.new(:email, String, title: 'Email Address', format: 'email').as_json
      expect(prop).to include_json(type: 'string', title: 'Email Address', format: 'email')
    end

    context 'with a union type' do
      it 'returns a json schema with anyOf property' do
        prop = described_class.new(:name, T.any(Integer, String)).as_json
        expect(prop).to include_json(anyOf: [{ type: 'integer' }, { type: 'string' }])
      end
    end
  end
end
