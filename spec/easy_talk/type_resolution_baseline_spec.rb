# frozen_string_literal: true

require 'spec_helper'

# Baseline specs that pin the current behavior of all type resolution logic
# scattered across multiple files. These specs exist to catch regressions
# when consolidating into TypeIntrospection.
#
# Each describe block targets a specific file's type resolution methods,
# documenting the exact inputs/outputs before refactoring.

RSpec.describe 'Type resolution baseline behavior' do
  let(:test_class) do
    Class.new do
      include EasyTalk::Model

      def self.name = 'TestModel'
    end
  end

  # ---------------------------------------------------------------------------
  # ValidationAdapters::Base — nilable_type?, extract_inner_type, get_type_class
  # ---------------------------------------------------------------------------
  describe EasyTalk::ValidationAdapters::Base do
    # Helper: create adapter instance to access protected methods
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
          # Should return the Simple type wrapping String or String itself
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
        # After extract_inner_type, should resolve to String
        resolved = result.respond_to?(:raw_type) ? result.raw_type : result
        expect(resolved).to eq(String)
      end

      it 'handles Symbol/String inputs by constantizing' do
        a = adapter(String)
        result = a.send(:get_type_class, :string)
        expect(result).to eq(String)
      end

      it 'falls back to String for unrecognized Symbol/String' do
        a = adapter(String)
        result = a.send(:get_type_class, :completely_unknown_type_xyz)
        expect(result).to eq(String)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # ErrorHelper — extract_element_type (different semantics: element type extraction)
  # ---------------------------------------------------------------------------
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

  # ---------------------------------------------------------------------------
  # Builders::ObjectBuilder — typed_array?, extract_inner_types, nilable_with_model?
  # ---------------------------------------------------------------------------
  describe EasyTalk::Builders::ObjectBuilder do
    # We need to instantiate via a schema definition to access private methods.
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

  # ---------------------------------------------------------------------------
  # ActiveModelAdapter — resolve_tuple_type_class, type_matches?, type_name_for_error
  # ---------------------------------------------------------------------------
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

  # ---------------------------------------------------------------------------
  # Cross-cutting: verify that Base and TypeIntrospection agree on all inputs
  # ---------------------------------------------------------------------------
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
        # Both return the TypedArray wrapper (not unwrapped to raw_type)
        expect(base_result).to be_a(T::Types::TypedArray)
        expect(ti_result).to be_a(T::Types::TypedArray)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Helper: create anonymous test classes with schema
  # ---------------------------------------------------------------------------
  private

  def test_class_with(&block)
    Class.new do
      include EasyTalk::Model

      def self.name = 'InlineTestModel'
      define_schema(&block)
    end
  end
end
