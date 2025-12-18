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
    it "returns a schema with 'anyOf' property" do
      prop = described_class.new(:name, T::AnyOf[Integer, String]).build
      expect(prop).to eq({ :type => 'object', 'anyOf' => [{ type: 'integer' }, { type: 'string' }] })
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
      end.to raise_error(ArgumentError, 'property type is not supported')
    end
  end

  # unsure if this should be supported
  context 'with a model' do
    let(:custom_class) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'CustomClass'
        end

        define_schema do
          property :name, String
        end
      end
    end

    context 'when the model is an array item' do
      it 'returns an array of custom class type' do
        prop = described_class.new(:name, T::Array[custom_class]).as_json
        expect(prop).to include_json({
                                       type: 'array',
                                       items: {
                                         type: 'object',
                                         properties: {
                                           name: {
                                             type: 'string'
                                           }
                                         },
                                         required: ['name']
                                       }
                                     })
      end
    end

    context 'when the model is a property' do
      it 'returns a custom class type' do
        prop = described_class.new(:name, custom_class).as_json
        expect(prop).to include_json({
                                       type: 'object',
                                       properties: {
                                         name: {
                                           type: 'string'
                                         }
                                       },
                                       required: ['name']
                                     })
      end

      it 'returns a custom class type with options' do
        prop = described_class.new(:name, custom_class, title: 'Custom Class', description: 'some description').as_json
        expect(prop).to include_json({
                                       type: 'object',
                                       title: 'Custom Class',
                                       description: 'some description',
                                       properties: {
                                         name: {
                                           type: 'string'
                                         }
                                       },
                                       required: ['name']
                                     })
      end
    end
  end

  context 'when calling as_json' do
    it 'returns a json schema' do
      prop = described_class.new(:name, String).as_json
      expect(prop).to include_json(type: 'string')
    end

    it 'returns a json schema with options' do
      prop = described_class.new(:email, String, title: 'Email Address', format: 'email').as_json
      expect(prop).to include_json(type: 'string', title: 'Email Address', format: 'email')
    end

    context 'with a union type' do
      pending 'returns a json schema with anyOf property' do
        prop = described_class.new(:name, T.any(Integer, String)).as_json
        expect(prop).to include_json(anyOf: [{ type: 'integer' }, { type: 'string' }])
      end
    end
  end
end
