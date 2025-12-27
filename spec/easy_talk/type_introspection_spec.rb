# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::TypeIntrospection do
  describe '.boolean_type?' do
    context 'with boolean types' do
      it 'returns true for TrueClass' do
        expect(described_class.boolean_type?(TrueClass)).to be true
      end

      it 'returns true for FalseClass' do
        expect(described_class.boolean_type?(FalseClass)).to be true
      end

      it 'returns true for T::Boolean' do
        expect(described_class.boolean_type?(T::Boolean)).to be true
      end
    end

    context 'with non-boolean types' do
      it 'returns false for String' do
        expect(described_class.boolean_type?(String)).to be false
      end

      it 'returns false for Integer' do
        expect(described_class.boolean_type?(Integer)).to be false
      end

      it 'returns false for nil' do
        expect(described_class.boolean_type?(nil)).to be false
      end

      it 'returns false for Array' do
        expect(described_class.boolean_type?(Array)).to be false
      end
    end
  end

  describe '.typed_array?' do
    context 'with typed arrays' do
      it 'returns true for T::Array[String]' do
        expect(described_class.typed_array?(T::Array[String])).to be true
      end

      it 'returns true for T::Array[Integer]' do
        expect(described_class.typed_array?(T::Array[Integer])).to be true
      end
    end

    context 'with non-typed arrays' do
      it 'returns false for Array class' do
        expect(described_class.typed_array?(Array)).to be false
      end

      it 'returns false for String' do
        expect(described_class.typed_array?(String)).to be false
      end

      it 'returns false for nil' do
        expect(described_class.typed_array?(nil)).to be false
      end
    end
  end

  describe '.nilable_type?' do
    context 'with nilable types' do
      it 'returns true for T.nilable(String)' do
        expect(described_class.nilable_type?(T.nilable(String))).to be true
      end

      it 'returns true for T.nilable(Integer)' do
        expect(described_class.nilable_type?(T.nilable(Integer))).to be true
      end
    end

    context 'with non-nilable types' do
      it 'returns false for String' do
        expect(described_class.nilable_type?(String)).to be false
      end

      it 'returns false for Integer' do
        expect(described_class.nilable_type?(Integer)).to be false
      end

      it 'returns false for nil' do
        expect(described_class.nilable_type?(nil)).to be false
      end
    end
  end

  describe '.primitive_type?' do
    context 'with primitive types' do
      it 'returns true for String' do
        expect(described_class.primitive_type?(String)).to be true
      end

      it 'returns true for Integer' do
        expect(described_class.primitive_type?(Integer)).to be true
      end

      it 'returns true for Float' do
        expect(described_class.primitive_type?(Float)).to be true
      end

      it 'returns true for TrueClass' do
        expect(described_class.primitive_type?(TrueClass)).to be true
      end

      it 'returns true for FalseClass' do
        expect(described_class.primitive_type?(FalseClass)).to be true
      end

      it 'returns true for NilClass' do
        expect(described_class.primitive_type?(NilClass)).to be true
      end
    end

    context 'with non-primitive types' do
      it 'returns false for Array' do
        expect(described_class.primitive_type?(Array)).to be false
      end

      it 'returns false for Hash' do
        expect(described_class.primitive_type?(Hash)).to be false
      end

      it 'returns false for nil' do
        expect(described_class.primitive_type?(nil)).to be false
      end
    end
  end

  describe '.json_schema_type' do
    context 'with primitive types' do
      it 'returns "string" for String' do
        expect(described_class.json_schema_type(String)).to eq('string')
      end

      it 'returns "integer" for Integer' do
        expect(described_class.json_schema_type(Integer)).to eq('integer')
      end

      it 'returns "number" for Float' do
        expect(described_class.json_schema_type(Float)).to eq('number')
      end

      it 'returns "number" for BigDecimal' do
        expect(described_class.json_schema_type(BigDecimal)).to eq('number')
      end

      it 'returns "boolean" for TrueClass' do
        expect(described_class.json_schema_type(TrueClass)).to eq('boolean')
      end

      it 'returns "boolean" for FalseClass' do
        expect(described_class.json_schema_type(FalseClass)).to eq('boolean')
      end

      it 'returns "boolean" for T::Boolean' do
        expect(described_class.json_schema_type(T::Boolean)).to eq('boolean')
      end

      it 'returns "null" for NilClass' do
        expect(described_class.json_schema_type(NilClass)).to eq('null')
      end
    end

    context 'with non-primitive types' do
      it 'returns "object" for nil' do
        expect(described_class.json_schema_type(nil)).to eq('object')
      end

      it 'returns class name lowercased for unknown types' do
        expect(described_class.json_schema_type(Array)).to eq('array')
      end
    end
  end

  describe '.get_type_class' do
    context 'with regular classes' do
      it 'returns the class itself for String' do
        expect(described_class.get_type_class(String)).to eq(String)
      end

      it 'returns the class itself for Integer' do
        expect(described_class.get_type_class(Integer)).to eq(Integer)
      end
    end

    context 'with boolean types' do
      it 'returns [TrueClass, FalseClass] for T::Boolean' do
        expect(described_class.get_type_class(T::Boolean)).to eq([TrueClass, FalseClass])
      end
    end

    context 'with typed arrays' do
      it 'returns Array for T::Array[String]' do
        expect(described_class.get_type_class(T::Array[String])).to eq(Array)
      end
    end

    context 'with nil' do
      it 'returns nil for nil' do
        expect(described_class.get_type_class(nil)).to be_nil
      end
    end
  end

  describe '.extract_inner_type' do
    context 'with nilable types' do
      it 'extracts String from T.nilable(String)' do
        result = described_class.extract_inner_type(T.nilable(String))
        expect(result).to eq(String)
      end

      it 'extracts Integer from T.nilable(Integer)' do
        result = described_class.extract_inner_type(T.nilable(Integer))
        expect(result).to eq(Integer)
      end
    end

    context 'with non-nilable types' do
      it 'returns String for String' do
        expect(described_class.extract_inner_type(String)).to eq(String)
      end

      it 'returns nil for nil' do
        expect(described_class.extract_inner_type(nil)).to be_nil
      end
    end
  end

  describe 'integration with EasyTalk models' do
    let(:test_model) do
      Class.new do
        include EasyTalk::Model

        def self.name = 'TypeIntrospectionTestModel'

        define_schema do
          property :name, String
          property :age, Integer
          property :active, T::Boolean
          property :tags, T::Array[String]
          property :nickname, T.nilable(String)
        end
      end
    end

    it 'correctly generates schema for boolean properties' do
      schema = test_model.json_schema
      expect(schema['properties']['active']['type']).to eq('boolean')
    end

    it 'correctly generates schema for string properties' do
      schema = test_model.json_schema
      expect(schema['properties']['name']['type']).to eq('string')
    end

    it 'correctly generates schema for array properties' do
      schema = test_model.json_schema
      expect(schema['properties']['tags']['type']).to eq('array')
    end
  end
end
