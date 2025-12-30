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

  context 'with an unknown type' do
    it 'raises UnknownTypeError' do
      unknown_type = Class.new
      expect do
        described_class.new(:field, unknown_type).build
      end.to raise_error(EasyTalk::UnknownTypeError, /Unknown type.*for property 'field'/)
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

  describe 'nilable types' do
    it 'returns schema with type array for T.nilable(String)' do
      prop = described_class.new(:name, T.nilable(String)).build
      expect(prop[:type]).to eq(%w[string null])
    end

    it 'returns schema with type array for T.nilable(Integer)' do
      prop = described_class.new(:count, T.nilable(Integer)).build
      expect(prop[:type]).to eq(%w[integer null])
    end

    it 'returns just null type when underlying type cannot be determined' do
      prop = described_class.new(:nothing, NilClass).build
      expect(prop).to eq({ type: 'null' })
    end

    it 'preserves constraints for nilable types' do
      prop = described_class.new(:name, T.nilable(String), min_length: 1).build
      expect(prop[:type]).to eq(%w[string null])
      expect(prop[:minLength]).to eq(1)
    end
  end

  describe '$ref support' do
    let(:model_class) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'RefModel'
        end

        define_schema do
          property :field, String
        end
      end
    end

    context 'with ref: true constraint' do
      around do |example|
        original_use_refs = EasyTalk.configuration.use_refs
        EasyTalk.configuration.use_refs = false
        example.run
        EasyTalk.configuration.use_refs = original_use_refs
      end

      it 'returns $ref schema for EasyTalk model' do
        prop = described_class.new(:nested, model_class, ref: true).build
        expect(prop).to have_key(:$ref)
        expect(prop[:$ref]).to eq('#/$defs/RefModel')
      end

      it 'preserves other constraints with $ref' do
        prop = described_class.new(:nested, model_class, ref: true, description: 'A nested model').build
        expect(prop[:$ref]).to eq('#/$defs/RefModel')
        expect(prop[:description]).to eq('A nested model')
      end
    end

    context 'with global use_refs enabled' do
      around do |example|
        original_use_refs = EasyTalk.configuration.use_refs
        EasyTalk.configuration.use_refs = true
        example.run
        EasyTalk.configuration.use_refs = original_use_refs
      end

      it 'uses $ref by default' do
        prop = described_class.new(:nested, model_class).build
        expect(prop).to have_key(:$ref)
      end

      it 'respects ref: false to inline' do
        prop = described_class.new(:nested, model_class, ref: false).build
        expect(prop).not_to have_key(:$ref)
        expect(prop[:type]).to eq('object')
      end
    end

    context 'with nilable EasyTalk model and $ref' do
      around do |example|
        original_use_refs = EasyTalk.configuration.use_refs
        EasyTalk.configuration.use_refs = true
        example.run
        EasyTalk.configuration.use_refs = original_use_refs
      end

      it 'uses anyOf with $ref and null for nilable model' do
        prop = described_class.new(:nested, T.nilable(model_class)).build
        expect(prop).to have_key(:anyOf)
        any_of = prop[:anyOf]
        expect(any_of).to include({ '$ref': '#/$defs/RefModel' })
        expect(any_of).to include({ type: 'null' })
      end
    end
  end

  describe '#find_builder_for_type' do
    it 'resolves builder for String type' do
      prop = described_class.new(:name, String)
      result = prop.send(:find_builder_for_type)
      expect(result.first).to eq(EasyTalk::Builders::StringBuilder)
    end

    it 'resolves builder for Integer type' do
      prop = described_class.new(:count, Integer)
      result = prop.send(:find_builder_for_type)
      expect(result.first).to eq(EasyTalk::Builders::IntegerBuilder)
    end

    it 'resolves builder for typed array' do
      prop = described_class.new(:items, T::Array[String])
      result = prop.send(:find_builder_for_type)
      expect(result.first).to eq(EasyTalk::Builders::TypedArrayBuilder)
      expect(result.last).to be true
    end
  end

  describe '#nilable_type?' do
    it 'returns true for T.nilable types' do
      prop = described_class.new(:name, T.nilable(String))
      expect(prop.send(:nilable_type?)).to be true
    end

    it 'returns false for non-nilable types' do
      prop = described_class.new(:name, String)
      expect(prop.send(:nilable_type?)).to be false
    end

    it 'returns false for types without :types method' do
      prop = described_class.new(:name, Integer)
      expect(prop.send(:nilable_type?)).to be false
    end
  end
end
