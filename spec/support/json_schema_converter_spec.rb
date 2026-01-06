# frozen_string_literal: true

require 'spec_helper'
require_relative 'json_schema_converter'

RSpec.describe JsonSchemaConverter do
  let(:converter) { described_class.new({}) }

  describe '#extract_type_and_constraints' do
    context 'with boolean schemas' do
      it 'returns String with optional for true' do
        type, constraints = converter.extract_type_and_constraints(true)
        expect(type).to eq(String)
        expect(constraints).to eq({ optional: true })
      end

      it 'returns String with optional for false' do
        type, constraints = converter.extract_type_and_constraints(false)
        expect(type).to eq(String)
        expect(constraints).to eq({ optional: true })
      end
    end

    context 'with string type' do
      it 'returns String type' do
        type, = converter.extract_type_and_constraints({ 'type' => 'string' })
        expect(type).to eq(String)
      end

      it 'extracts string constraints' do
        prop_def = {
          'type' => 'string',
          'minLength' => 1,
          'maxLength' => 100,
          'pattern' => '^\w+$',
          'format' => 'email'
        }
        _, constraints = converter.extract_type_and_constraints(prop_def)
        expect(constraints).to include(
          min_length: 1,
          max_length: 100,
          pattern: '^\w+$',
          format: 'email'
        )
      end
    end

    context 'with integer type' do
      it 'returns Integer type' do
        type, = converter.extract_type_and_constraints({ 'type' => 'integer' })
        expect(type).to eq(Integer)
      end

      it 'extracts numeric constraints' do
        prop_def = {
          'type' => 'integer',
          'minimum' => 0,
          'maximum' => 100,
          'exclusiveMinimum' => -1,
          'exclusiveMaximum' => 101,
          'multipleOf' => 5
        }
        _, constraints = converter.extract_type_and_constraints(prop_def)
        expect(constraints).to include(
          minimum: 0,
          maximum: 100,
          exclusive_minimum: -1,
          exclusive_maximum: 101,
          multiple_of: 5
        )
      end
    end

    context 'with number type' do
      it 'returns Float type' do
        type, = converter.extract_type_and_constraints({ 'type' => 'number' })
        expect(type).to eq(Float)
      end
    end

    context 'with boolean type' do
      it 'returns T::Boolean type' do
        type, = converter.extract_type_and_constraints({ 'type' => 'boolean' })
        expect(type).to eq(T::Boolean)
      end
    end

    context 'with array type' do
      it 'returns untyped Array by default (no item type validation)' do
        type, = converter.extract_type_and_constraints({ 'type' => 'array' })
        expect(type).to eq(Array)
      end

      it 'extracts item type from items schema' do
        prop_def = {
          'type' => 'array',
          'items' => { 'type' => 'integer' }
        }
        type, = converter.extract_type_and_constraints(prop_def)
        expect(type).to eq(T::Array[Integer])
      end

      it 'extracts array constraints' do
        prop_def = {
          'type' => 'array',
          'minItems' => 1,
          'maxItems' => 10,
          'uniqueItems' => true
        }
        _, constraints = converter.extract_type_and_constraints(prop_def)
        expect(constraints).to include(
          min_items: 1,
          max_items: 10,
          unique_items: true
        )
      end
    end

    context 'with nullable types' do
      it 'wraps type in T.nilable for ["string", "null"]' do
        prop_def = { 'type' => %w[string null] }
        type, = converter.extract_type_and_constraints(prop_def)
        expect(type).to be_a(T::Types::Union)
        expect(type.nilable?).to be true
      end

      it 'wraps type in T.nilable for ["integer", "null"]' do
        prop_def = { 'type' => %w[integer null] }
        type, = converter.extract_type_and_constraints(prop_def)
        expect(type).to be_a(T::Types::Union)
        expect(type.nilable?).to be true
      end
    end

    context 'with common constraints' do
      it 'extracts enum constraint' do
        prop_def = { 'type' => 'string', 'enum' => %w[a b c] }
        _, constraints = converter.extract_type_and_constraints(prop_def)
        expect(constraints).to include(enum: %w[a b c])
      end

      it 'extracts const constraint' do
        prop_def = { 'type' => 'string', 'const' => 'fixed_value' }
        _, constraints = converter.extract_type_and_constraints(prop_def)
        expect(constraints).to include(const: 'fixed_value')
      end

      it 'extracts default constraint' do
        prop_def = { 'type' => 'string', 'default' => 'default_value' }
        _, constraints = converter.extract_type_and_constraints(prop_def)
        expect(constraints).to include(default: 'default_value')
      end
    end
  end

  describe '#to_class' do
    it 'creates a valid EasyTalk model class' do
      schema = {
        'type' => 'object',
        'properties' => {
          'name' => { 'type' => 'string', 'minLength' => 1 },
          'age' => { 'type' => 'integer', 'minimum' => 0 }
        },
        'required' => %w[name]
      }

      model_class = described_class.new(schema).to_class
      expect(model_class.ancestors).to include(EasyTalk::Model)

      # Verify schema was generated correctly
      json_schema = model_class.json_schema
      expect(json_schema['properties']['name']).to include('type' => 'string', 'minLength' => 1)
      expect(json_schema['properties']['age']).to include('type' => 'integer', 'minimum' => 0)
      expect(json_schema['required']).to include('name')
    end
  end
end
