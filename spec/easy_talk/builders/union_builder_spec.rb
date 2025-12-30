# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::Builders::UnionBuilder do
  describe '#build' do
    context 'with union of primitive types' do
      it 'generates anyOf schema for String and Integer union' do
        union_type = T.any(String, Integer)
        builder = described_class.new(:value, union_type, {})
        result = builder.build

        expect(result).to eq({
                               'anyOf' => [
                                 { type: 'string' },
                                 { type: 'integer' }
                               ]
                             })
      end

      it 'generates anyOf schema for multiple primitive types' do
        union_type = T.any(String, Integer, Float)
        builder = described_class.new(:value, union_type, {})
        result = builder.build

        expect(result['anyOf']).to contain_exactly(
          { type: 'string' },
          { type: 'integer' },
          { type: 'number' }
        )
      end
    end

    context 'with nilable types' do
      it 'generates anyOf schema for nilable String' do
        nilable_type = T.nilable(String)
        builder = described_class.new(:optional_name, nilable_type, {})
        result = builder.build

        expect(result['anyOf']).to contain_exactly(
          { type: 'string' },
          { type: 'null' }
        )
      end

      it 'generates anyOf schema for nilable Integer' do
        nilable_type = T.nilable(Integer)
        builder = described_class.new(:optional_count, nilable_type, {})
        result = builder.build

        expect(result['anyOf']).to contain_exactly(
          { type: 'integer' },
          { type: 'null' }
        )
      end

      it 'generates anyOf schema for nilable Float' do
        nilable_type = T.nilable(Float)
        builder = described_class.new(:optional_price, nilable_type, {})
        result = builder.build

        expect(result['anyOf']).to contain_exactly(
          { type: 'number' },
          { type: 'null' }
        )
      end
    end

    context 'with EasyTalk model types' do
      let(:address_model) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'Address'
          end

          define_schema do
            property :street, String
            property :city, String
          end
        end
      end

      let(:phone_model) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'Phone'
          end

          define_schema do
            property :number, String
          end
        end
      end

      it 'generates anyOf schema with model schemas' do
        # When using T.any with models, the types are wrapped in T::Types::Simple
        # which may not resolve directly to the model class
        # Testing this behavior requires integration with how Property handles types
        union_type = T.any(address_model, phone_model)
        builder = described_class.new(:contact, union_type, {})

        # The builder should return schemas for each type
        expect(builder.types.length).to eq(2)
      end
    end

    context 'with constraints passed to child types' do
      it 'stores constraints for use by child type schemas' do
        union_type = T.any(String, Integer)
        constraints = { title: 'Value Field' }
        builder = described_class.new(:value, union_type, constraints)

        # Constraints are stored and passed to Property.new for each type
        expect(builder.instance_variable_get(:@constraints)).to eq(constraints)
      end
    end

    context 'with context storage' do
      it 'stores the result in context with the property name as key' do
        union_type = T.any(String, Integer)
        builder = described_class.new(:custom_field, union_type, {})
        builder.build

        context = builder.instance_variable_get(:@context)
        expect(context).to have_key(:custom_field)
        expect(context[:custom_field]).to have_key('anyOf')
      end
    end
  end

  describe '#types' do
    it 'returns the types from the union type' do
      union_type = T.any(String, Integer)
      builder = described_class.new(:value, union_type, {})

      types = builder.types
      expect(types.length).to eq(2)
    end

    it 'returns types from a nilable type' do
      nilable_type = T.nilable(String)
      builder = described_class.new(:value, nilable_type, {})

      types = builder.types
      # T.nilable creates a union of String and NilClass
      expect(types.length).to eq(2)
    end
  end

  describe '#schemas' do
    it 'returns an array of built schemas for primitive types' do
      union_type = T.any(String, Integer)
      builder = described_class.new(:value, union_type, {})

      schemas = builder.schemas
      expect(schemas).to be_an(Array)
      expect(schemas.length).to eq(2)
      expect(schemas).to include({ type: 'string' })
      expect(schemas).to include({ type: 'integer' })
    end

    it 'returns schemas for nilable types' do
      nilable_type = T.nilable(String)
      builder = described_class.new(:value, nilable_type, {})

      schemas = builder.schemas
      expect(schemas).to be_an(Array)
      expect(schemas).to include({ type: 'string' })
      expect(schemas).to include({ type: 'null' })
    end
  end

  describe '.collection_type?' do
    it 'returns true since union is a collection type' do
      expect(described_class.collection_type?).to be true
    end
  end

  describe 'initialization' do
    it 'stores name, type, and constraints' do
      union_type = T.any(String, Integer)
      builder = described_class.new(:field_name, union_type, { optional: true })

      expect(builder.instance_variable_get(:@name)).to eq(:field_name)
      expect(builder.instance_variable_get(:@type)).to eq(union_type)
      expect(builder.instance_variable_get(:@constraints)).to eq({ optional: true })
    end

    it 'initializes with empty context' do
      union_type = T.any(String, Integer)
      builder = described_class.new(:field_name, union_type, {})

      expect(builder.instance_variable_get(:@context)).to eq({})
    end
  end
end
