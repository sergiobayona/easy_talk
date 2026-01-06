# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::JsonSchemaEquality do
  describe '.duplicates?' do
    context 'with primitive types' do
      it 'detects duplicate integers' do
        expect(described_class.duplicates?([1, 2, 1])).to be(true)
      end

      it 'accepts unique integers' do
        expect(described_class.duplicates?([1, 2, 3])).to be(false)
      end

      it 'detects duplicate strings' do
        expect(described_class.duplicates?(%w[foo bar foo])).to be(true)
      end

      it 'accepts unique strings' do
        expect(described_class.duplicates?(%w[foo bar baz])).to be(false)
      end

      it 'accepts empty arrays' do
        expect(described_class.duplicates?([])).to be(false)
      end

      it 'accepts single-element arrays' do
        expect(described_class.duplicates?([1])).to be(false)
      end
    end

    context 'with mathematical equality for numbers' do
      it 'treats 1 and 1.0 as duplicates' do
        expect(described_class.duplicates?([1, 1.0])).to be(true)
      end

      it 'treats 1.0 and 1.00 as duplicates' do
        expect(described_class.duplicates?([1.0, 1.00])).to be(true)
      end

      it 'treats 1, 1.0, and 1.00 as duplicates' do
        expect(described_class.duplicates?([1.0, 1.00, 1])).to be(true)
      end

      it 'treats different numbers as unique' do
        expect(described_class.duplicates?([1, 2, 3.0])).to be(false)
      end
    end

    context 'with type distinction for non-numbers' do
      it 'treats true and 1 as unique' do
        expect(described_class.duplicates?([true, 1])).to be(false)
      end

      it 'treats false and 0 as unique' do
        expect(described_class.duplicates?([false, 0])).to be(false)
      end

      it 'treats [1] and [true] as unique' do
        expect(described_class.duplicates?([[1], [true]])).to be(false)
      end

      it 'treats [0] and [false] as unique' do
        expect(described_class.duplicates?([[0], [false]])).to be(false)
      end

      it 'treats {"a": true} and {"a": 1} as unique' do
        expect(described_class.duplicates?([{ 'a' => true }, { 'a' => 1 }])).to be(false)
      end

      it 'treats {"a": false} and {"a": 0} as unique' do
        expect(described_class.duplicates?([{ 'a' => false }, { 'a' => 0 }])).to be(false)
      end
    end

    context 'with objects/hashes' do
      it 'treats objects with same keys in different order as duplicates' do
        expect(described_class.duplicates?([{ 'a' => 1, 'b' => 2 }, { 'b' => 2, 'a' => 1 }])).to be(true)
      end

      it 'treats objects with different values as unique' do
        expect(described_class.duplicates?([{ 'a' => 1, 'b' => 2 }, { 'a' => 2, 'b' => 1 }])).to be(false)
      end

      it 'treats identical objects as duplicates' do
        expect(described_class.duplicates?([{ 'foo' => 'bar' }, { 'foo' => 'bar' }])).to be(true)
      end

      it 'treats different objects as unique' do
        expect(described_class.duplicates?([{ 'foo' => 'bar' }, { 'foo' => 'baz' }])).to be(false)
      end
    end

    context 'with nested structures' do
      it 'detects duplicate nested objects' do
        expect(described_class.duplicates?([
                                             { 'foo' => { 'bar' => { 'baz' => true } } },
                                             { 'foo' => { 'bar' => { 'baz' => true } } }
                                           ])).to be(true)
      end

      it 'accepts unique nested objects' do
        expect(described_class.duplicates?([
                                             { 'foo' => { 'bar' => { 'baz' => true } } },
                                             { 'foo' => { 'bar' => { 'baz' => false } } }
                                           ])).to be(false)
      end

      it 'treats nested objects with different key order as duplicates' do
        expect(described_class.duplicates?([
                                             { 'foo' => { 'a' => 1, 'b' => 2 } },
                                             { 'foo' => { 'b' => 2, 'a' => 1 } }
                                           ])).to be(true)
      end

      it 'detects duplicate arrays' do
        expect(described_class.duplicates?([%w[foo], %w[foo]])).to be(true)
      end

      it 'accepts unique arrays' do
        expect(described_class.duplicates?([%w[foo], %w[bar]])).to be(false)
      end

      it 'detects duplicates in arrays with more than two elements' do
        expect(described_class.duplicates?([%w[foo], %w[bar], %w[foo]])).to be(true)
      end

      it 'handles deeply nested structures' do
        expect(described_class.duplicates?([
                                             [[1], 'foo'],
                                             [[true], 'foo']
                                           ])).to be(false)

        expect(described_class.duplicates?([
                                             [[1], 'foo'],
                                             [[1], 'foo']
                                           ])).to be(true)
      end
    end

    context 'with heterogeneous types' do
      it 'accepts unique heterogeneous types' do
        expect(described_class.duplicates?([{}, [1], true, nil, 1, '{}'])).to be(false)
      end

      it 'detects duplicates in heterogeneous types' do
        expect(described_class.duplicates?([{}, [1], true, nil, {}, 1])).to be(true)
      end
    end
  end

  describe '.normalize' do
    it 'normalizes integers to rationals' do
      expect(described_class.normalize(1)).to eq(1.to_r)
    end

    it 'normalizes floats to rationals' do
      expect(described_class.normalize(1.0)).to eq(1.to_r)
    end

    it 'preserves booleans' do
      expect(described_class.normalize(true)).to eq(true)
      expect(described_class.normalize(false)).to eq(false)
    end

    it 'preserves strings' do
      expect(described_class.normalize('foo')).to eq('foo')
    end

    it 'preserves nil' do
      expect(described_class.normalize(nil)).to be_nil
    end

    it 'normalizes hashes by sorting keys' do
      normalized = described_class.normalize({ 'b' => 2, 'a' => 1 })
      expect(normalized).to eq([['a', 1.to_r], ['b', 2.to_r]])
    end

    it 'normalizes arrays recursively' do
      normalized = described_class.normalize([1, 'foo', { 'a' => 1 }])
      expect(normalized).to eq([1.to_r, 'foo', [['a', 1.to_r]]])
    end
  end
end
