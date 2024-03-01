# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EsquemaBase::Property do
  it 'returns a type string' do
    prop = described_class.new('name', String).build_property
    expect(prop).to eq(type: 'string')
  end

  it 'returns a type integer' do
    prop = described_class.new('name', Integer).build_property
    expect(prop).to eq(type: 'integer')
  end

  it 'returns a type number' do
    prop = described_class.new('name', Float).build_property
    expect(prop).to eq(type: 'number')
  end

  it 'returns a type boolean' do
    prop = described_class.new('name', T::Boolean).build_property
    expect(prop).to eq(type: 'boolean')
  end

  it 'returns a type null' do
    prop = described_class.new('name', NilClass).build_property
    expect(prop).to eq(type: 'null')
  end

  it 'returns an array of strings type' do
    prop = described_class.new('name', T::Array[String]).build_property
    expect(prop).to eq(type: 'array', items: { type: 'string' })
  end

  it 'returns an array of integers type' do
    prop = described_class.new('name', T::Array[Integer]).build_property
    expect(prop).to eq(type: 'array', items: { type: 'integer' })
  end

  context 'array with custom simple class' do
    class CustomClass; end

    it 'returns an array of custom class type' do
      prop = described_class.new('name', T::Array[CustomClass]).build_property
      expect(prop).to eq(type: 'array', items: { type: 'object' })
    end
  end

  context 'array with custom class with a schema defined' do
    let(:user) do
      Class.new do
        include EsquemaBase::Model

        define_schema do
          property :name, String
          property :email, String, format: 'email'
          property :age, Integer
        end
      end
    end

    it 'returns an array of custom class type' do
      prop = described_class.new('name', T::Array[user]).build_property
      expect(prop[:type]).to eq('array')
      expect(prop[:items]).to include(type: 'object')
      expect(prop[:items][:properties].keys).to eq(%i[name email age])
      expect(prop[:items][:properties][:name]).to be_a(EsquemaBase::Property)
    end
  end

  # it 'returns an object type' do
  #   prop = described_class.new('name', T::Hash[Symbol, String]).build_property
  #   expect(prop).to eq(type: 'object')
  # end

  # it 'raises an error when type is not supported' do
  #   expect { described_class.new('name', Object).build_property }.to raise_error('Type Object not supported')
  # end
end
