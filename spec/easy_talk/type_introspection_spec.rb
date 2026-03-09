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

      it 'returns true for a T.any(TrueClass, FalseClass) union' do
        union = T.any(TrueClass, FalseClass)
        expect(described_class.boolean_type?(union)).to be true
      end

      it 'returns true for a Sorbet simple type wrapping TrueClass' do
        wrapper = T::Utils.coerce(TrueClass)
        expect(described_class.boolean_type?(wrapper)).to be true
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

  describe '.boolean_union_type?' do
    it 'returns true for [TrueClass, FalseClass]' do
      expect(described_class.boolean_union_type?([TrueClass, FalseClass])).to be true
    end

    it 'returns true for [FalseClass, TrueClass] (order independent)' do
      expect(described_class.boolean_union_type?([FalseClass, TrueClass])).to be true
    end

    it 'returns false for a single boolean class' do
      expect(described_class.boolean_union_type?(TrueClass)).to be false
    end

    it 'returns false for a non-boolean array' do
      expect(described_class.boolean_union_type?([String, Integer])).to be false
    end

    it 'returns false for an empty array' do
      expect(described_class.boolean_union_type?([])).to be false
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

  describe '.array_type?' do
    it 'returns true for plain Array class' do
      expect(described_class.array_type?(Array)).to be true
    end

    it 'returns true for T::Array[String]' do
      expect(described_class.array_type?(T::Array[String])).to be true
    end

    it 'returns true for T::Tuple[String, Integer]' do
      expect(described_class.array_type?(T::Tuple[String, Integer])).to be true
    end

    it 'returns false for String' do
      expect(described_class.array_type?(String)).to be false
    end

    it 'returns false for nil' do
      expect(described_class.array_type?(nil)).to be false
    end

    it 'returns false for Hash' do
      expect(described_class.array_type?(Hash)).to be false
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

      it 'returns true for T.nilable(Float)' do
        expect(described_class.nilable_type?(T.nilable(Float))).to be true
      end

      it 'returns true for T.nilable(T::Boolean)' do
        expect(described_class.nilable_type?(T.nilable(T::Boolean))).to be true
      end

      it 'returns true for T.nilable(T::Array[String])' do
        expect(described_class.nilable_type?(T.nilable(T::Array[String]))).to be true
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

      it 'returns true for BigDecimal' do
        expect(described_class.primitive_type?(BigDecimal)).to be true
      end

      it 'returns true for a Sorbet simple type wrapping String' do
        wrapper = T::Utils.coerce(String)
        expect(described_class.primitive_type?(wrapper)).to be true
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

      it 'returns false for Date' do
        expect(described_class.primitive_type?(Date)).to be false
      end

      it 'returns false for DateTime' do
        expect(described_class.primitive_type?(DateTime)).to be false
      end

      it 'returns false for Time' do
        expect(described_class.primitive_type?(Time)).to be false
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

      it 'returns "date" for Date' do
        expect(described_class.json_schema_type(Date)).to eq('date')
      end

      it 'returns "datetime" for DateTime' do
        expect(described_class.json_schema_type(DateTime)).to eq('datetime')
      end

      it 'returns "time" for Time' do
        expect(described_class.json_schema_type(Time)).to eq('time')
      end

      it 'resolves Sorbet simple type wrapper via raw_type' do
        wrapper = T::Utils.coerce(Integer)
        expect(described_class.json_schema_type(wrapper)).to eq('integer')
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

    context 'with Sorbet simple type wrappers' do
      it 'returns the raw_type for a wrapped Float' do
        wrapper = T::Utils.coerce(Float)
        expect(described_class.get_type_class(wrapper)).to eq(Float)
      end
    end

    context 'with tuple types' do
      it 'returns Array for T::Tuple[String, Integer]' do
        expect(described_class.get_type_class(T::Tuple[String, Integer])).to eq(Array)
      end
    end

    context 'with nilable types' do
      it 'unwraps T.nilable(String) to String' do
        expect(described_class.get_type_class(T.nilable(String))).to eq(String)
      end

      it 'unwraps T.nilable(Integer) to Integer' do
        expect(described_class.get_type_class(T.nilable(Integer))).to eq(Integer)
      end

      it 'unwraps T.nilable(T::Array[String]) to Array' do
        expect(described_class.get_type_class(T.nilable(T::Array[String]))).to eq(Array)
      end
    end

    context 'with Symbol/String inputs' do
      it 'constantizes a known type from Symbol' do
        expect(described_class.get_type_class(:string)).to eq(String)
      end

      it 'constantizes a known type from String' do
        expect(described_class.get_type_class('integer')).to eq(Integer)
      end

      it 'returns nil for an unknown type name' do
        expect(described_class.get_type_class(:completely_unknown_xyz)).to be_nil
      end
    end

    context 'with unrecognized types' do
      it 'returns nil for an arbitrary object' do
        expect(described_class.get_type_class(Object.new)).to be_nil
      end

      it 'returns nil for a non-nilable union like T.any(Integer, Float)' do
        union = T.any(Integer, Float)
        expect(described_class.get_type_class(union)).to be_nil
      end

      it 'returns nil for a composition type like T::AnyOf' do
        composer = T::AnyOf[Integer, String]
        expect(described_class.get_type_class(composer)).to be_nil
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

      it 'extracts Float from T.nilable(Float)' do
        result = described_class.extract_inner_type(T.nilable(Float))
        expect(result).to eq(Float)
      end

      it 'extracts TypedArray from T.nilable(T::Array[String])' do
        result = described_class.extract_inner_type(T.nilable(T::Array[String]))
        expect(result).to be_a(T::Types::TypedArray)
      end

      it 'extracts a non-nil type from T.nilable(T::Boolean)' do
        result = described_class.extract_inner_type(T.nilable(T::Boolean))
        # T.nilable(T::Boolean) unwraps to a non-NilClass member of the union
        expect(result).not_to eq(NilClass)
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

  # ===========================================================================
  # Integration tests — public API only (define_schema, json_schema, .new,
  # .valid?, .errors) exercising edge cases around type introspection.
  # ===========================================================================

  describe 'integration' do
    # -------------------------------------------------------------------------
    # Nilable primitives with constraints
    # -------------------------------------------------------------------------
    context 'nilable primitives with constraints' do
      describe 'T.nilable(String) with length constraints' do
        let(:model) do
          Class.new do
            include EasyTalk::Model

            def self.name = 'NilableStringModel'

            define_schema do
              property :label, T.nilable(String), min_length: 2, max_length: 10
            end
          end
        end

        it 'accepts nil' do
          expect(model.new(label: nil)).to be_valid
        end

        it 'accepts a string within bounds' do
          expect(model.new(label: 'hello')).to be_valid
        end

        it 'rejects a string shorter than min_length' do
          instance = model.new(label: 'x')
          expect(instance).not_to be_valid
          expect(instance.errors[:label]).not_to be_empty
        end

        it 'rejects a string longer than max_length' do
          instance = model.new(label: 'a' * 11)
          expect(instance).not_to be_valid
          expect(instance.errors[:label]).not_to be_empty
        end

        it 'generates JSON Schema with nullable type' do
          schema = model.json_schema
          prop = schema['properties']['label']
          expect(prop['type']).to include('null')
          expect(prop['type']).to include('string')
        end

        it 'includes length constraints in JSON Schema' do
          prop = model.json_schema['properties']['label']
          expect(prop['minLength']).to eq(2)
          expect(prop['maxLength']).to eq(10)
        end
      end

      describe 'T.nilable(String) with pattern constraint' do
        let(:model) do
          Class.new do
            include EasyTalk::Model

            def self.name = 'NilablePatternModel'

            define_schema do
              property :code, T.nilable(String), pattern: '\\A[A-Z]{3}\\z'
            end
          end
        end

        it 'accepts nil' do
          expect(model.new(code: nil)).to be_valid
        end

        it 'accepts a matching string' do
          expect(model.new(code: 'ABC')).to be_valid
        end

        it 'rejects a non-matching string' do
          expect(model.new(code: 'abc')).not_to be_valid
        end
      end

      describe 'T.nilable(String) with email format' do
        let(:model) do
          Class.new do
            include EasyTalk::Model

            def self.name = 'NilableEmailModel'

            define_schema do
              property :email, T.nilable(String), format: 'email'
            end
          end
        end

        it 'accepts nil' do
          expect(model.new(email: nil)).to be_valid
        end

        it 'accepts a valid email' do
          expect(model.new(email: 'user@example.com')).to be_valid
        end

        it 'rejects an invalid email' do
          expect(model.new(email: 'not-an-email')).not_to be_valid
        end
      end

      describe 'T.nilable(Integer) with range constraints' do
        let(:model) do
          Class.new do
            include EasyTalk::Model

            def self.name = 'NilableIntModel'

            define_schema do
              property :count, T.nilable(Integer), minimum: 0, maximum: 100
            end
          end
        end

        it 'accepts nil' do
          expect(model.new(count: nil)).to be_valid
        end

        it 'accepts an integer within range' do
          expect(model.new(count: 50)).to be_valid
        end

        it 'accepts the boundary values' do
          expect(model.new(count: 0)).to be_valid
          expect(model.new(count: 100)).to be_valid
        end

        it 'rejects below minimum' do
          instance = model.new(count: -1)
          expect(instance).not_to be_valid
          expect(instance.errors[:count]).not_to be_empty
        end

        it 'rejects above maximum' do
          instance = model.new(count: 101)
          expect(instance).not_to be_valid
          expect(instance.errors[:count]).not_to be_empty
        end

        it 'generates JSON Schema with nullable integer' do
          prop = model.json_schema['properties']['count']
          expect(prop['type']).to include('null')
          expect(prop['type']).to include('integer')
          expect(prop['minimum']).to eq(0)
          expect(prop['maximum']).to eq(100)
        end
      end

      describe 'T.nilable(Float) with range constraints' do
        let(:model) do
          Class.new do
            include EasyTalk::Model

            def self.name = 'NilableFloatModel'

            define_schema do
              property :score, T.nilable(Float), minimum: 0.0, maximum: 1.0
            end
          end
        end

        it 'accepts nil' do
          expect(model.new(score: nil)).to be_valid
        end

        it 'accepts a float within range' do
          expect(model.new(score: 0.5)).to be_valid
        end

        it 'rejects below minimum' do
          expect(model.new(score: -0.1)).not_to be_valid
        end

        it 'rejects above maximum' do
          expect(model.new(score: 1.1)).not_to be_valid
        end

        it 'generates JSON Schema with nullable number' do
          prop = model.json_schema['properties']['score']
          expect(prop['type']).to include('null')
          expect(prop['type']).to include('number')
        end
      end

      describe 'T.nilable(String) with enum constraint' do
        let(:model) do
          Class.new do
            include EasyTalk::Model

            def self.name = 'NilableEnumModel'

            define_schema do
              property :status, T.nilable(String), enum: %w[active inactive pending]
            end
          end
        end

        it 'accepts nil' do
          expect(model.new(status: nil)).to be_valid
        end

        it 'accepts a value in the enum' do
          expect(model.new(status: 'active')).to be_valid
        end

        it 'rejects a value not in the enum' do
          expect(model.new(status: 'unknown')).not_to be_valid
        end
      end

      describe 'T.nilable(Integer) with enum' do
        let(:model) do
          Class.new do
            include EasyTalk::Model

            def self.name = 'NilableIntEnumModel'

            define_schema do
              property :priority, T.nilable(Integer), enum: [1, 2, 3]
            end
          end
        end

        it 'accepts nil' do
          expect(model.new(priority: nil)).to be_valid
        end

        it 'accepts a value in the enum' do
          expect(model.new(priority: 2)).to be_valid
        end

        it 'rejects a value not in the enum' do
          expect(model.new(priority: 99)).not_to be_valid
        end
      end
    end

    # -------------------------------------------------------------------------
    # Temporal types (Date, DateTime, Time)
    # -------------------------------------------------------------------------
    context 'temporal types' do
      describe 'Date property' do
        let(:model) do
          Class.new do
            include EasyTalk::Model

            def self.name = 'DateModel'

            define_schema do
              property :born_on, Date
            end
          end
        end

        it 'generates JSON Schema with string type and date format' do
          prop = model.json_schema['properties']['born_on']
          expect(prop['type']).to eq('string')
          expect(prop['format']).to eq('date')
        end

        it 'accepts a Date value' do
          expect(model.new(born_on: Date.today)).to be_valid
        end
      end

      describe 'DateTime property' do
        let(:model) do
          Class.new do
            include EasyTalk::Model

            def self.name = 'DateTimeModel'

            define_schema do
              property :created_at, DateTime
            end
          end
        end

        it 'generates JSON Schema with string type and date-time format' do
          prop = model.json_schema['properties']['created_at']
          expect(prop['type']).to eq('string')
          expect(prop['format']).to eq('date-time')
        end
      end

      describe 'Time property' do
        let(:model) do
          Class.new do
            include EasyTalk::Model

            def self.name = 'TimeModel'

            define_schema do
              property :starts_at, Time
            end
          end
        end

        it 'generates JSON Schema with string type and time format' do
          prop = model.json_schema['properties']['starts_at']
          expect(prop['type']).to eq('string')
          expect(prop['format']).to eq('time')
        end
      end

      describe 'T.nilable(Date)' do
        let(:model) do
          Class.new do
            include EasyTalk::Model

            def self.name = 'NilableDateModel'

            define_schema do
              property :born_on, T.nilable(Date)
            end
          end
        end

        it 'accepts nil' do
          expect(model.new(born_on: nil)).to be_valid
        end

        it 'accepts a Date' do
          expect(model.new(born_on: Date.today)).to be_valid
        end

        it 'generates JSON Schema with nullable string and date format' do
          prop = model.json_schema['properties']['born_on']
          expect(prop['type']).to include('null')
          expect(prop['type']).to include('string')
          expect(prop['format']).to eq('date')
        end
      end
    end

    # -------------------------------------------------------------------------
    # BigDecimal
    # -------------------------------------------------------------------------
    context 'BigDecimal type' do
      describe 'BigDecimal property with constraints' do
        let(:model) do
          Class.new do
            include EasyTalk::Model

            def self.name = 'BigDecimalModel'

            define_schema do
              property :price, BigDecimal, minimum: 0
            end
          end
        end

        it 'generates JSON Schema with number type' do
          prop = model.json_schema['properties']['price']
          expect(prop['type']).to eq('number')
          expect(prop['minimum']).to eq(0)
        end

        it 'accepts a BigDecimal value' do
          expect(model.new(price: BigDecimal('9.99'))).to be_valid
        end

        it 'rejects below minimum' do
          expect(model.new(price: BigDecimal('-1'))).not_to be_valid
        end
      end

      describe 'T.nilable(BigDecimal)' do
        let(:model) do
          Class.new do
            include EasyTalk::Model

            def self.name = 'NilableBigDecimalModel'

            define_schema do
              property :amount, T.nilable(BigDecimal)
            end
          end
        end

        it 'accepts nil' do
          expect(model.new(amount: nil)).to be_valid
        end

        it 'accepts a BigDecimal value' do
          expect(model.new(amount: BigDecimal('42.5'))).to be_valid
        end

        it 'generates JSON Schema with nullable number type' do
          prop = model.json_schema['properties']['amount']
          expect(prop['type']).to include('null')
          expect(prop['type']).to include('number')
        end
      end
    end

    # -------------------------------------------------------------------------
    # Nilable booleans
    # -------------------------------------------------------------------------
    context 'nilable booleans' do
      describe 'T.nilable(T::Boolean)' do
        let(:model) do
          Class.new do
            include EasyTalk::Model

            def self.name = 'NilableBoolModel'

            define_schema do
              property :active, T.nilable(T::Boolean)
            end
          end
        end

        it 'accepts nil' do
          expect(model.new(active: nil)).to be_valid
        end

        it 'accepts true' do
          expect(model.new(active: true)).to be_valid
        end

        it 'accepts false' do
          expect(model.new(active: false)).to be_valid
        end

        it 'rejects a string' do
          expect(model.new(active: 'yes')).not_to be_valid
        end

        it 'rejects an integer' do
          expect(model.new(active: 1)).not_to be_valid
        end

        it 'generates JSON Schema with nullable boolean' do
          prop = model.json_schema['properties']['active']
          expect(prop['type']).to include('null')
          expect(prop['type']).to include('boolean')
        end
      end
    end

    # -------------------------------------------------------------------------
    # Nilable arrays
    # -------------------------------------------------------------------------
    context 'nilable arrays' do
      describe 'T.nilable(T::Array[String]) without constraints' do
        let(:model) do
          Class.new do
            include EasyTalk::Model

            def self.name = 'NilableArrayModel'

            define_schema do
              property :tags, T.nilable(T::Array[String])
            end
          end
        end

        it 'accepts nil' do
          expect(model.new(tags: nil)).to be_valid
        end

        it 'accepts an empty array' do
          expect(model.new(tags: [])).to be_valid
        end

        it 'accepts a populated array' do
          expect(model.new(tags: %w[a b c])).to be_valid
        end

        it 'rejects array items of the wrong type' do
          expect(model.new(tags: [1, 2, 3])).not_to be_valid
        end
      end

      describe 'T.nilable(T::Array[String]) with min_items constraint' do
        let(:model) do
          Class.new do
            include EasyTalk::Model

            def self.name = 'NilableArrayMinItemsModel'

            define_schema do
              property :items, T.nilable(T::Array[String]), min_items: 1, max_items: 5
            end
          end
        end

        it 'accepts nil because the type is explicitly T.nilable' do
          instance = model.new(items: nil)
          expect(instance).to be_valid
        end

        it 'accepts an array within bounds' do
          expect(model.new(items: ['a'])).to be_valid
          expect(model.new(items: %w[a b c d e])).to be_valid
        end

        it 'rejects an empty array' do
          expect(model.new(items: [])).not_to be_valid
        end

        it 'rejects an array exceeding max_items' do
          expect(model.new(items: %w[a b c d e f])).not_to be_valid
        end
      end

      describe 'T.nilable(T::Array[EasyTalkModel])' do
        let(:tag_model) do
          Class.new do
            include EasyTalk::Model

            def self.name = 'Tag'

            define_schema do
              property :label, String
            end
          end
        end

        let(:model) do
          tag = tag_model
          Class.new do
            include EasyTalk::Model

            def self.name = 'NilableModelArrayModel'

            define_schema do
              property :tags, T.nilable(T::Array[tag])
            end
          end
        end

        it 'accepts nil' do
          expect(model.new(tags: nil)).to be_valid
        end

        it 'accepts an array of valid model instances' do
          expect(model.new(tags: [tag_model.new(label: 'ruby')])).to be_valid
        end

        it 'rejects an array containing invalid model instances' do
          instance = model.new(tags: [tag_model.new(label: nil)])
          expect(instance).not_to be_valid
        end
      end

      describe 'T.nilable(T::Array[T::Boolean])' do
        let(:model) do
          Class.new do
            include EasyTalk::Model

            def self.name = 'NilableBoolArrayModel'

            define_schema do
              property :flags, T.nilable(T::Array[T::Boolean])
            end
          end
        end

        it 'accepts nil' do
          expect(model.new(flags: nil)).to be_valid
        end

        it 'accepts an array of booleans' do
          instance = model.new(flags: [true, false, true])
          expect(instance).to be_valid
        end
      end

      describe 'T::Array[Integer] (non-nilable) item type validation' do
        let(:model) do
          Class.new do
            include EasyTalk::Model

            def self.name = 'IntArrayModel'

            define_schema do
              property :numbers, T::Array[Integer]
            end
          end
        end

        it 'accepts an array of integers' do
          expect(model.new(numbers: [1, 2, 3])).to be_valid
        end

        it 'rejects an array of strings' do
          expect(model.new(numbers: %w[a b c])).not_to be_valid
        end

        it 'rejects nil (not nilable)' do
          expect(model.new(numbers: nil)).not_to be_valid
        end
      end
    end

    # -------------------------------------------------------------------------
    # Nilable nested models
    # -------------------------------------------------------------------------
    context 'nilable nested models' do
      describe 'T.nilable(EasyTalkModel) nested property' do
        let(:address_model) do
          Class.new do
            include EasyTalk::Model

            def self.name = 'Address'

            define_schema do
              property :street, String
              property :city, String
            end
          end
        end

        let(:model) do
          addr = address_model
          Class.new do
            include EasyTalk::Model

            def self.name = 'PersonWithOptionalAddress'

            define_schema do
              property :name, String
              property :address, T.nilable(addr)
            end
          end
        end

        it 'accepts nil for the nested model' do
          expect(model.new(name: 'Alice', address: nil)).to be_valid
        end

        it 'accepts a valid model instance' do
          addr = address_model.new(street: '123 Main', city: 'Boston')
          expect(model.new(name: 'Alice', address: addr)).to be_valid
        end

        it 'auto-instantiates from a hash' do
          instance = model.new(name: 'Alice', address: { street: '123 Main', city: 'Boston' })
          expect(instance.address).to be_a(address_model)
          expect(instance).to be_valid
        end

        it 'propagates nested validation errors' do
          addr = address_model.new(street: nil, city: nil)
          instance = model.new(name: 'Alice', address: addr)
          expect(instance).not_to be_valid
        end

        it 'generates JSON Schema with null in type' do
          prop = model.json_schema['properties']['address']
          expect(prop['type']).to include('null')
          expect(prop['type']).to include('object')
        end
      end

      describe 'shared nested nilable model across multiple parents' do
        let(:shared_model) do
          Class.new do
            include EasyTalk::Model

            def self.name = 'SharedAddress'

            define_schema do
              property :city, String
            end
          end
        end

        let(:model_a) do
          shared = shared_model
          Class.new do
            include EasyTalk::Model

            def self.name = 'ModelA'

            define_schema do
              property :home, T.nilable(shared)
            end
          end
        end

        let(:model_b) do
          shared = shared_model
          Class.new do
            include EasyTalk::Model

            def self.name = 'ModelB'

            define_schema do
              property :work, T.nilable(shared)
            end
          end
        end

        it 'both models accept nil independently' do
          expect(model_a.new(home: nil)).to be_valid
          expect(model_b.new(work: nil)).to be_valid
        end

        it 'both models accept valid instances independently' do
          addr = shared_model.new(city: 'Boston')
          expect(model_a.new(home: addr)).to be_valid
          expect(model_b.new(work: addr)).to be_valid
        end

        it 'validation in one does not leak into the other' do
          invalid_addr = shared_model.new(city: nil)
          valid_addr = shared_model.new(city: 'Boston')

          a = model_a.new(home: invalid_addr)
          b = model_b.new(work: valid_addr)

          expect(a).not_to be_valid
          expect(b).to be_valid
        end
      end
    end

    # -------------------------------------------------------------------------
    # Tuple properties
    # -------------------------------------------------------------------------
    context 'tuple properties' do
      describe 'T::Tuple properties' do
        let(:model) do
          Class.new do
            include EasyTalk::Model

            def self.name = 'TupleModel'

            define_schema do
              property :coordinates, T::Tuple[Float, Float]
              property :record, T::Tuple[String, Integer, T::Boolean], additional_items: false
            end
          end
        end

        it 'accepts a valid tuple' do
          expect(model.new(coordinates: [1.0, 2.0], record: ['a', 1, true])).to be_valid
        end

        it 'rejects wrong types in tuple positions' do
          instance = model.new(coordinates: %w[not floats], record: ['a', 1, true])
          expect(instance).not_to be_valid
        end

        it 'rejects additional items when additional_items: false' do
          instance = model.new(coordinates: [1.0, 2.0], record: ['a', 1, true, 'extra'])
          expect(instance).not_to be_valid
        end

        it 'generates JSON Schema with positional items' do
          schema = model.json_schema
          coord_schema = schema['properties']['coordinates']
          expect(coord_schema['type']).to eq('array')
          expect(coord_schema['items']).to be_an(Array)
          expect(coord_schema['items'].length).to eq(2)
          expect(coord_schema['items']).to all(include('type' => 'number'))
        end
      end
    end

    # -------------------------------------------------------------------------
    # Composition types
    # -------------------------------------------------------------------------
    context 'composition types' do
      describe 'composition types with nilable models' do
        let(:email_model) do
          Class.new do
            include EasyTalk::Model

            def self.name = 'EmailContact'

            define_schema do
              property :email, String, format: 'email'
            end
          end
        end

        let(:phone_model) do
          Class.new do
            include EasyTalk::Model

            def self.name = 'PhoneContact'

            define_schema do
              property :number, String
            end
          end
        end

        let(:model) do
          email = email_model
          phone = phone_model
          Class.new do
            include EasyTalk::Model

            def self.name = 'ContactModel'

            define_schema do
              property :contact, T::OneOf[email, phone]
            end
          end
        end

        it 'generates JSON Schema with oneOf' do
          schema = model.json_schema
          contact = schema['properties']['contact']
          expect(contact).to have_key('oneOf')
        end
      end

      describe 'T::AnyOf composition' do
        let(:email_model) do
          Class.new do
            include EasyTalk::Model

            def self.name = 'EmailContact'

            define_schema do
              property :email, String
            end
          end
        end

        let(:phone_model) do
          Class.new do
            include EasyTalk::Model

            def self.name = 'PhoneContact'

            define_schema do
              property :number, String
            end
          end
        end

        let(:model) do
          email = email_model
          phone = phone_model
          Class.new do
            include EasyTalk::Model

            def self.name = 'AnyOfContactModel'

            define_schema do
              property :contact, T::AnyOf[email, phone]
            end
          end
        end

        it 'generates JSON Schema with anyOf' do
          contact = model.json_schema['properties']['contact']
          expect(contact).to have_key('anyOf')
          expect(contact['anyOf'].length).to eq(2)
        end
      end

      describe 'T::AllOf composition' do
        let(:base_model) do
          Class.new do
            include EasyTalk::Model

            def self.name = 'BaseInfo'

            define_schema do
              property :id, Integer
            end
          end
        end

        let(:detail_model) do
          Class.new do
            include EasyTalk::Model

            def self.name = 'DetailInfo'

            define_schema do
              property :name, String
            end
          end
        end

        let(:model) do
          base = base_model
          detail = detail_model
          Class.new do
            include EasyTalk::Model

            def self.name = 'AllOfModel'

            define_schema do
              property :info, T::AllOf[base, detail]
            end
          end
        end

        it 'generates JSON Schema with allOf' do
          info = model.json_schema['properties']['info']
          expect(info).to have_key('allOf')
          expect(info['allOf'].length).to eq(2)
        end
      end
    end

    # -------------------------------------------------------------------------
    # Required-ness semantics
    # -------------------------------------------------------------------------
    context 'required-ness semantics' do
      describe 'required-ness with nilable types' do
        let(:model) do
          Class.new do
            include EasyTalk::Model

            def self.name = 'RequirednessModel'

            define_schema do
              property :required_field, String
              property :nilable_field, T.nilable(String)
              property :optional_field, String, optional: true
            end
          end
        end

        it 'marks required_field as required' do
          expect(model.json_schema['required']).to include('required_field')
        end

        it 'marks nilable_field as required in JSON Schema (nullable != optional)' do
          expect(model.json_schema['required']).to include('nilable_field')
        end

        it 'does not mark optional_field as required' do
          expect(model.json_schema['required']).not_to include('optional_field')
        end

        it 'validates: required_field must be present' do
          expect(model.new(required_field: nil)).not_to be_valid
        end

        it 'validates: nilable_field accepts nil' do
          expect(model.new(required_field: 'hi', nilable_field: nil)).to be_valid
        end

        it 'validates: optional_field accepts nil (absent)' do
          expect(model.new(required_field: 'hi')).to be_valid
        end
      end
    end

    # -------------------------------------------------------------------------
    # Kitchen sink — all nilable types combined
    # -------------------------------------------------------------------------
    context 'kitchen sink model' do
      describe 'model with every nilable type' do
        let(:address_model) do
          Class.new do
            include EasyTalk::Model

            def self.name = 'Address'

            define_schema do
              property :street, String
            end
          end
        end

        let(:model) do
          addr = address_model
          Class.new do
            include EasyTalk::Model

            def self.name = 'KitchenSinkModel'

            define_schema do
              property :name, String
              property :nickname, T.nilable(String), max_length: 20
              property :age, T.nilable(Integer), minimum: 0
              property :score, T.nilable(Float), minimum: 0.0, maximum: 100.0
              property :active, T.nilable(T::Boolean)
              property :tags, T.nilable(T::Array[String])
              property :address, T.nilable(addr)
            end
          end
        end

        it 'generates JSON Schema with all properties' do
          keys = model.json_schema['properties'].keys
          expect(keys).to contain_exactly(
            'name', 'nickname', 'age', 'score', 'active', 'tags', 'address'
          )
        end

        it 'requires only the non-nilable property' do
          expect(model.json_schema['required']).to include('name')
        end

        it 'validates with all nilable fields set to nil' do
          instance = model.new(
            name: 'Alice', nickname: nil, age: nil,
            score: nil, active: nil, tags: nil, address: nil
          )
          expect(instance).to be_valid
        end

        it 'validates with all fields populated' do
          instance = model.new(
            name: 'Alice', nickname: 'Ali', age: 25, score: 85.5,
            active: true, tags: %w[dev ruby],
            address: address_model.new(street: '123 Main')
          )
          expect(instance).to be_valid
        end

        it 'collects errors from multiple invalid nilable fields' do
          instance = model.new(
            name: 'Alice',
            nickname: 'a' * 21,
            age: -1,
            score: 101.0,
            active: 'yes',
            tags: nil,
            address: nil
          )
          expect(instance).not_to be_valid
          expect(instance.errors[:nickname]).not_to be_empty
          expect(instance.errors[:age]).not_to be_empty
          expect(instance.errors[:score]).not_to be_empty
          expect(instance.errors[:active]).not_to be_empty
        end
      end
    end
  end

  # Regression: PR #173 — baseline specs that pin the behavior of all type
  # resolution logic. These catch regressions when consolidating into
  # TypeIntrospection.
  describe 'type resolution baseline behavior' do
    let(:test_class) do
      Class.new do
        include EasyTalk::Model

        def self.name = 'TestModel'
      end
    end

    describe EasyTalk::ValidationAdapters::Base do
      def adapter(type, constraints = {})
        described_class.new(test_class, :field, type, constraints)
      end

      describe '#nilable_type?' do
        it 'returns true for T.nilable(String)' do
          expect(adapter(T.nilable(String)).send(:nilable_type?)).to be true
        end

        it 'returns true for T.nilable(Integer)' do
          expect(adapter(T.nilable(Integer)).send(:nilable_type?)).to be true
        end

        it 'returns true for T.nilable(T::Boolean)' do
          expect(adapter(T.nilable(T::Boolean)).send(:nilable_type?)).to be true
        end

        it 'returns true for T.nilable(T::Array[String])' do
          expect(adapter(T.nilable(T::Array[String])).send(:nilable_type?)).to be true
        end

        it 'returns false for plain String' do
          expect(adapter(String).send(:nilable_type?)).to be false
        end

        it 'returns false for Integer' do
          expect(adapter(Integer).send(:nilable_type?)).to be false
        end

        it 'returns false for T::Boolean' do
          expect(adapter(T::Boolean).send(:nilable_type?)).to be false
        end

        it 'returns false for T::Array[String]' do
          expect(adapter(T::Array[String]).send(:nilable_type?)).to be false
        end

        it 'accepts an explicit type argument' do
          a = adapter(String)
          expect(a.send(:nilable_type?, T.nilable(Integer))).to be true
          expect(a.send(:nilable_type?, Integer)).to be false
        end
      end

      describe '#extract_inner_type' do
        it 'extracts String from T.nilable(String)' do
          result = adapter(T.nilable(String)).send(:extract_inner_type)
          expect(result).to eq(String)
        end

        it 'extracts Integer from T.nilable(Integer)' do
          result = adapter(T.nilable(Integer)).send(:extract_inner_type)
          expect(result).to eq(Integer)
        end

        it 'preserves TypedArray from T.nilable(T::Array[String])' do
          nilable_array = T.nilable(T::Array[String])
          result = adapter(nilable_array).send(:extract_inner_type)
          expect(result).to be_a(T::Types::TypedArray)
        end

        it 'returns the type itself for plain String' do
          result = adapter(String).send(:extract_inner_type)
          expect(result).to eq(String)
        end

        it 'returns the type itself for Integer' do
          result = adapter(Integer).send(:extract_inner_type)
          expect(result).to eq(Integer)
        end

        it 'accepts an explicit type argument' do
          a = adapter(String)
          result = a.send(:extract_inner_type, T.nilable(Float))
          expect(result).to eq(Float)
        end

        context 'with union types (T.any)' do
          it 'finds the non-nil type from T.any(String, NilClass) via .types' do
            union = T.any(String, NilClass)
            result = adapter(union).send(:extract_inner_type)
            resolved = result.respond_to?(:raw_type) ? result.raw_type : result
            expect(resolved).to eq(String)
          end
        end
      end

      describe '#get_type_class' do
        it 'returns the class itself for a plain Class' do
          expect(adapter(String).send(:get_type_class, String)).to eq(String)
          expect(adapter(Integer).send(:get_type_class, Integer)).to eq(Integer)
          expect(adapter(Float).send(:get_type_class, Float)).to eq(Float)
        end

        it 'returns raw_type for Sorbet Simple types' do
          simple_type = T::Utils.coerce(String)
          expect(adapter(String).send(:get_type_class, simple_type)).to eq(String)
        end

        it 'returns Array for T::Types::TypedArray' do
          typed_array = T::Array[String]
          expect(adapter(typed_array).send(:get_type_class, typed_array)).to eq(Array)
        end

        it 'returns Array for EasyTalk::Types::Tuple' do
          tuple = T::Tuple[String, Integer]
          expect(adapter(tuple).send(:get_type_class, tuple)).to eq(Array)
        end

        it 'returns [TrueClass, FalseClass] for T::Boolean' do
          expect(adapter(T::Boolean).send(:get_type_class, T::Boolean)).to eq([TrueClass, FalseClass])
        end

        it 'unwraps nilable types to get the inner type class' do
          nilable_str = T.nilable(String)
          a = adapter(nilable_str)
          result = a.send(:get_type_class, nilable_str)
          resolved = result.respond_to?(:raw_type) ? result.raw_type : result
          expect(resolved).to eq(String)
        end

        it 'handles Symbol/String inputs by constantizing' do
          a = adapter(String)
          result = a.send(:get_type_class, :string)
          expect(result).to eq(String)
        end

        it 'returns nil for unrecognized Symbol/String' do
          a = adapter(String)
          result = a.send(:get_type_class, :completely_unknown_type_xyz)
          expect(result).to be_nil
        end
      end
    end

    describe EasyTalk::ErrorHelper, '.extract_element_type' do
      context 'with T::Array (TypedArray with Simple inner type)' do
        it 'extracts String from T::Array[String]' do
          expect(described_class.extract_element_type(T::Array[String])).to eq(String)
        end

        it 'extracts Integer from T::Array[Integer]' do
          expect(described_class.extract_element_type(T::Array[Integer])).to eq(Integer)
        end
      end

      context 'with T::Array[T::Boolean]' do
        it 'returns T::Boolean' do
          expect(described_class.extract_element_type(T::Array[T::Boolean])).to eq(T::Boolean)
        end
      end

      context 'with union types (T.any)' do
        it 'returns an array of the constituent raw types' do
          union = T.any(String, Integer)
          result = described_class.extract_element_type(union)
          expect(result).to be_an(Array)
          expect(result).to include(String)
          expect(result).to include(Integer)
        end
      end

      context 'with T.nilable (which is a union with NilClass)' do
        it 'returns an array including the inner type and NilClass' do
          nilable = T.nilable(String)
          result = described_class.extract_element_type(nilable)
          expect(result).to be_an(Array)
          expect(result).to include(String)
          expect(result).to include(NilClass)
        end
      end

      context 'with unrecognized types' do
        it 'returns Object as fallback' do
          expect(described_class.extract_element_type(Object.new)).to eq(Object)
        end
      end
    end

    describe EasyTalk::Builders::ObjectBuilder do
      let(:address_model) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'Address'
          define_schema do
            property :street, String
          end
        end
      end

      def builder_for(model_class)
        described_class.new(model_class.schema_definition)
      end

      describe 'typed_array? (now delegated to TypeIntrospection)' do
        it 'returns true for T::Array[String]' do
          expect(EasyTalk::TypeIntrospection.typed_array?(T::Array[String])).to be true
        end

        it 'returns true for T::Array[Integer]' do
          expect(EasyTalk::TypeIntrospection.typed_array?(T::Array[Integer])).to be true
        end

        it 'returns false for plain Array' do
          expect(EasyTalk::TypeIntrospection.typed_array?(Array)).to be false
        end

        it 'returns false for String' do
          expect(EasyTalk::TypeIntrospection.typed_array?(String)).to be false
        end

        it 'returns false for nil' do
          expect(EasyTalk::TypeIntrospection.typed_array?(nil)).to be false
        end
      end

      describe '#extract_inner_types (private)' do
        it 'extracts the raw_type from a simple typed array' do
          b = builder_for(test_class_with { property :items, T::Array[String] })
          result = b.send(:extract_inner_types, T::Array[String])
          expect(result).to eq([String])
        end

        it 'extracts Integer from T::Array[Integer]' do
          b = builder_for(test_class_with { property :items, T::Array[Integer] })
          result = b.send(:extract_inner_types, T::Array[Integer])
          expect(result).to eq([Integer])
        end

        it 'returns empty array for non-typed-array' do
          b = builder_for(test_class_with { property :items, String })
          expect(b.send(:extract_inner_types, String)).to eq([])
        end

        it 'extracts items from Composer inside typed array' do
          addr = address_model
          b = builder_for(test_class_with { property :items, T::Array[String] })
          composer = EasyTalk::Types::Composer::AnyOf.new(addr)
          typed_array_with_composer = T::Array[composer]
          result = b.send(:extract_inner_types, typed_array_with_composer)
          expect(result).to eq([addr])
        end
      end

      describe '#nilable_with_model? (private)' do
        it 'returns true for T.nilable(EasyTalkModel)' do
          addr = address_model
          b = builder_for(test_class_with { property :x, String })
          nilable_model = T.nilable(addr)
          expect(b.send(:nilable_with_model?, nilable_model)).to be true
        end

        it 'returns false for T.nilable(String)' do
          b = builder_for(test_class_with { property :x, String })
          expect(b.send(:nilable_with_model?, T.nilable(String))).to be false
        end

        it 'returns false for plain String' do
          b = builder_for(test_class_with { property :x, String })
          expect(b.send(:nilable_with_model?, String)).to be false
        end

        it 'returns false for plain EasyTalk model (not nilable)' do
          addr = address_model
          b = builder_for(test_class_with { property :x, String })
          expect(b.send(:nilable_with_model?, addr)).to be false
        end

        it 'returns false for T.nilable(Integer)' do
          b = builder_for(test_class_with { property :x, String })
          expect(b.send(:nilable_with_model?, T.nilable(Integer))).to be false
        end
      end
    end

    describe EasyTalk::ValidationAdapters::ActiveModelAdapter do
      describe '.resolve_tuple_type_class' do
        it 'returns the class itself for a plain Class' do
          expect(described_class.resolve_tuple_type_class(String)).to eq(String)
          expect(described_class.resolve_tuple_type_class(Integer)).to eq(Integer)
        end

        it 'returns raw_type for Sorbet Simple types' do
          simple = T::Utils.coerce(String)
          expect(described_class.resolve_tuple_type_class(simple)).to eq(String)
        end

        it 'returns [TrueClass, FalseClass] for T::Boolean' do
          expect(described_class.resolve_tuple_type_class(T::Boolean)).to eq([TrueClass, FalseClass])
        end

        it 'returns :untyped for T.untyped' do
          expect(described_class.resolve_tuple_type_class(T.untyped)).to eq(:untyped)
        end

        it 'flattens union types recursively' do
          union = T.any(String, Integer)
          result = [described_class.resolve_tuple_type_class(union)].flatten
          expect(result).to include(String)
          expect(result).to include(Integer)
        end

        it 'handles T.nilable by flattening the union' do
          nilable = T.nilable(String)
          result = [described_class.resolve_tuple_type_class(nilable)].flatten
          expect(result).to include(String)
          expect(result).to include(NilClass)
        end
      end

      describe '.type_matches?' do
        it 'returns true when value matches the type class' do
          expect(described_class.type_matches?('hello', String)).to be true
          expect(described_class.type_matches?(42, Integer)).to be true
        end

        it 'returns false when value does not match' do
          expect(described_class.type_matches?(42, String)).to be false
          expect(described_class.type_matches?('hello', Integer)).to be false
        end

        it 'returns true for :untyped regardless of value' do
          expect(described_class.type_matches?('anything', :untyped)).to be true
          expect(described_class.type_matches?(42, :untyped)).to be true
          expect(described_class.type_matches?(nil, :untyped)).to be true
        end

        it 'handles array type classes (union match)' do
          expect(described_class.type_matches?(true, [TrueClass, FalseClass])).to be true
          expect(described_class.type_matches?(false, [TrueClass, FalseClass])).to be true
          expect(described_class.type_matches?('nope', [TrueClass, FalseClass])).to be false
        end
      end

      describe '.type_name_for_error' do
        it 'returns the class name for a simple class' do
          expect(described_class.type_name_for_error(String)).to eq('String')
          expect(described_class.type_name_for_error(Integer)).to eq('Integer')
        end

        it 'returns joined names for array of classes' do
          result = described_class.type_name_for_error([TrueClass, FalseClass])
          expect(result).to eq('TrueClass or FalseClass')
        end

        it 'returns "unknown" for nil' do
          expect(described_class.type_name_for_error(nil)).to eq('unknown')
        end
      end
    end

    describe 'Base vs TypeIntrospection parity' do
      def adapter(type)
        EasyTalk::ValidationAdapters::Base.new(test_class, :field, type, {})
      end

      shared_examples 'nilable_type? agrees' do |type|
        it "for #{type}" do
          base_result = adapter(type).send(:nilable_type?, type)
          ti_result = EasyTalk::TypeIntrospection.nilable_type?(type)
          expect(base_result).to eq(ti_result)
        end
      end

      [
        String, Integer, Float, T::Boolean,
        T::Array[String], T::Array[Integer],
        T.nilable(String), T.nilable(Integer),
        T.nilable(T::Boolean), T.nilable(T::Array[String])
      ].each do |type|
        include_examples 'nilable_type? agrees', type
      end

      describe 'extract_inner_type' do
        it 'both extract String from T.nilable(String)' do
          type = T.nilable(String)
          base_result = adapter(type).send(:extract_inner_type, type)
          ti_result = EasyTalk::TypeIntrospection.extract_inner_type(type)
          expect(base_result).to eq(ti_result)
        end

        it 'both extract Integer from T.nilable(Integer)' do
          type = T.nilable(Integer)
          base_result = adapter(type).send(:extract_inner_type, type)
          ti_result = EasyTalk::TypeIntrospection.extract_inner_type(type)
          expect(base_result).to eq(ti_result)
        end

        it 'both preserve TypedArray from T.nilable(T::Array[String])' do
          type = T.nilable(T::Array[String])
          base_result = adapter(type).send(:extract_inner_type, type)
          ti_result = EasyTalk::TypeIntrospection.extract_inner_type(type)
          expect(base_result).to be_a(T::Types::TypedArray)
          expect(ti_result).to be_a(T::Types::TypedArray)
        end
      end
    end

    def test_class_with(&block)
      Class.new do
        include EasyTalk::Model

        def self.name = 'InlineTestModel'
        define_schema(&block)
      end
    end
  end
end
