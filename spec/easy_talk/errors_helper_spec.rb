# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::ErrorHelper do
  describe '.raise_constraint_error' do
    it 'raises a ConstraintError with formatted message' do
      expect do
        described_class.raise_constraint_error(
          property_name: :age,
          constraint_name: :minimum,
          expected: Integer,
          got: 'string'
        )
      end.to raise_error(
        EasyTalk::ConstraintError,
        "Error in property 'age': Constraint 'minimum' expects Integer, but received \"string\" (String)."
      )
    end

    it 'includes the value class in the error message' do
      expect do
        described_class.raise_constraint_error(
          property_name: :value,
          constraint_name: :maximum,
          expected: 'a number',
          got: [1, 2, 3]
        )
      end.to raise_error(EasyTalk::ConstraintError, /\(Array\)/)
    end
  end

  describe '.raise_array_constraint_error' do
    it 'raises a ConstraintError with index information' do
      expect do
        described_class.raise_array_constraint_error(
          property_name: :items,
          constraint_name: :enum,
          index: 2,
          expected: String,
          got: 123
        )
      end.to raise_error(
        EasyTalk::ConstraintError,
        "Error in property 'items': Constraint 'enum' at index 2 expects String, but received 123 (Integer)."
      )
    end
  end

  describe '.raise_unknown_option_error' do
    it 'raises an UnknownOptionError with valid options listed' do
      expect do
        described_class.raise_unknown_option_error(
          property_name: :name,
          option: :unknown,
          valid_options: %i[minimum maximum]
        )
      end.to raise_error(
        EasyTalk::UnknownOptionError,
        "Unknown option 'unknown' for property 'name'. Valid options are: minimum, maximum."
      )
    end

    it 'extracts option name from hash' do
      expect do
        described_class.raise_unknown_option_error(
          property_name: :name,
          option: { invalid_key: 'value' },
          valid_options: %i[min max]
        )
      end.to raise_error(EasyTalk::UnknownOptionError, /Unknown option 'invalid_key'/)
    end
  end

  describe '.extract_inner_type' do
    context 'with typed array' do
      it 'extracts the raw type from typed array' do
        type_info = T::Array[String]
        expect(described_class.extract_inner_type(type_info)).to eq(String)
      end

      it 'extracts Integer from typed array' do
        type_info = T::Array[Integer]
        expect(described_class.extract_inner_type(type_info)).to eq(Integer)
      end
    end

    context 'with boolean type' do
      it 'returns T::Boolean for boolean typed arrays' do
        type_info = T::Array[T::Boolean]
        expect(described_class.extract_inner_type(type_info)).to eq(T::Boolean)
      end
    end

    context 'with union types' do
      it 'extracts both types from union' do
        type_info = T.any(String, Integer)
        result = described_class.extract_inner_type(type_info)
        expect(result).to include(String)
        expect(result).to include(Integer)
      end
    end

    context 'with fallback' do
      it 'returns Object when type cannot be extracted' do
        expect(described_class.extract_inner_type(Object.new)).to eq(Object)
      end
    end
  end

  describe '.validate_typed_array_values' do
    context 'when value is not an array' do
      it 'raises a ConstraintError' do
        expect do
          described_class.validate_typed_array_values(
            property_name: :items,
            constraint_name: :enum,
            type_info: T::Array[String],
            array_value: 'not an array'
          )
        end.to raise_error(EasyTalk::ConstraintError, /expects String/)
      end
    end

    context 'when array contains invalid elements' do
      it 'raises error for wrong type at specific index' do
        expect do
          described_class.validate_typed_array_values(
            property_name: :items,
            constraint_name: :enum,
            type_info: T::Array[String],
            array_value: ['valid', 123, 'also valid']
          )
        end.to raise_error(EasyTalk::ConstraintError, /at index 1 expects String/)
      end
    end

    context 'when array is valid' do
      it 'does not raise error for valid string array' do
        expect do
          described_class.validate_typed_array_values(
            property_name: :items,
            constraint_name: :enum,
            type_info: T::Array[String],
            array_value: %w[one two three]
          )
        end.not_to raise_error
      end

      it 'does not raise error for valid integer array' do
        expect do
          described_class.validate_typed_array_values(
            property_name: :items,
            constraint_name: :enum,
            type_info: T::Array[Integer],
            array_value: [1, 2, 3]
          )
        end.not_to raise_error
      end
    end
  end

  describe '.validate_array_element' do
    context 'with union type' do
      it 'validates against multiple allowed types' do
        expect do
          described_class.validate_array_element(
            property_name: :values,
            constraint_name: :enum,
            inner_type: [String, Integer],
            element: 'valid',
            index: 0
          )
        end.not_to raise_error
      end

      it 'raises error when element matches no union type' do
        expect do
          described_class.validate_array_element(
            property_name: :values,
            constraint_name: :enum,
            inner_type: [String, Integer],
            element: 3.14,
            index: 0
          )
        end.to raise_error(EasyTalk::ConstraintError, /expects String or Integer/)
      end
    end

    context 'with single type' do
      it 'validates element type' do
        expect do
          described_class.validate_array_element(
            property_name: :values,
            constraint_name: :enum,
            inner_type: String,
            element: 123,
            index: 0
          )
        end.to raise_error(EasyTalk::ConstraintError)
      end
    end
  end

  describe '.validate_union_element' do
    it 'allows element matching any type in union' do
      expect do
        described_class.validate_union_element(:field, :constraint, [String, Integer], 'string', 0)
      end.not_to raise_error

      expect do
        described_class.validate_union_element(:field, :constraint, [String, Integer], 42, 0)
      end.not_to raise_error
    end

    it 'raises error when element matches no type' do
      expect do
        described_class.validate_union_element(:field, :constraint, [String, Integer], [], 0)
      end.to raise_error(EasyTalk::ConstraintError)
    end
  end

  describe '.validate_single_type_element' do
    it 'allows boolean values regardless of expected type' do
      expect do
        described_class.validate_single_type_element(:field, :constraint, String, true, 0)
      end.not_to raise_error
    end

    it 'raises error for invalid boolean when boolean expected' do
      expect do
        described_class.validate_single_type_element(:field, :constraint, T::Boolean, 'not_boolean', 0)
      end.to raise_error(EasyTalk::ConstraintError, /Boolean/)
    end

    it 'raises error for type mismatch' do
      expect do
        described_class.validate_single_type_element(:field, :constraint, Integer, 'string', 0)
      end.to raise_error(EasyTalk::ConstraintError)
    end

    it 'allows matching type' do
      expect do
        described_class.validate_single_type_element(:field, :constraint, String, 'valid', 0)
      end.not_to raise_error
    end
  end

  describe '.validate_constraint_value' do
    context 'with nil value' do
      it 'returns early without error' do
        expect do
          described_class.validate_constraint_value(
            property_name: :field,
            constraint_name: :minimum,
            value_type: Integer,
            value: nil
          )
        end.not_to raise_error
      end
    end

    context 'with boolean type' do
      it 'accepts true' do
        expect do
          described_class.validate_constraint_value(
            property_name: :field,
            constraint_name: :default,
            value_type: T::Boolean,
            value: true
          )
        end.not_to raise_error
      end

      it 'accepts false' do
        expect do
          described_class.validate_constraint_value(
            property_name: :field,
            constraint_name: :default,
            value_type: T::Boolean,
            value: false
          )
        end.not_to raise_error
      end

      it 'rejects non-boolean' do
        expect do
          described_class.validate_constraint_value(
            property_name: :field,
            constraint_name: :default,
            value_type: T::Boolean,
            value: 'true'
          )
        end.to raise_error(EasyTalk::ConstraintError, /Boolean/)
      end

      it 'accepts array of booleans' do
        expect do
          described_class.validate_constraint_value(
            property_name: :field,
            constraint_name: :enum,
            value_type: T::Boolean,
            value: [true, false]
          )
        end.not_to raise_error
      end
    end

    context 'with simple scalar types' do
      it 'validates String type' do
        expect do
          described_class.validate_constraint_value(
            property_name: :name,
            constraint_name: :default,
            value_type: String,
            value: 'valid'
          )
        end.not_to raise_error
      end

      it 'raises error for String type mismatch' do
        expect do
          described_class.validate_constraint_value(
            property_name: :name,
            constraint_name: :default,
            value_type: String,
            value: 123
          )
        end.to raise_error(EasyTalk::ConstraintError)
      end

      it 'validates Integer type' do
        expect do
          described_class.validate_constraint_value(
            property_name: :count,
            constraint_name: :minimum,
            value_type: Integer,
            value: 42
          )
        end.not_to raise_error
      end

      it 'raises error for Integer type mismatch' do
        expect do
          described_class.validate_constraint_value(
            property_name: :count,
            constraint_name: :minimum,
            value_type: Integer,
            value: '42'
          )
        end.to raise_error(EasyTalk::ConstraintError)
      end
    end

    context 'with typed array' do
      it 'validates array elements' do
        expect do
          described_class.validate_constraint_value(
            property_name: :items,
            constraint_name: :enum,
            value_type: T::Array[String],
            value: %w[a b c]
          )
        end.not_to raise_error
      end

      it 'raises error for invalid array elements' do
        expect do
          described_class.validate_constraint_value(
            property_name: :items,
            constraint_name: :enum,
            value_type: T::Array[String],
            value: ['valid', 123]
          )
        end.to raise_error(EasyTalk::ConstraintError)
      end
    end

    context 'with union Sorbet type' do
      it 'validates against union of types' do
        expect do
          described_class.validate_constraint_value(
            property_name: :value,
            constraint_name: :default,
            value_type: T.any(String, Integer),
            value: 'string'
          )
        end.not_to raise_error
      end

      it 'accepts integer in union' do
        expect do
          described_class.validate_constraint_value(
            property_name: :value,
            constraint_name: :default,
            value_type: T.any(String, Integer),
            value: 42
          )
        end.not_to raise_error
      end

      it 'raises error for value not in union' do
        expect do
          described_class.validate_constraint_value(
            property_name: :value,
            constraint_name: :default,
            value_type: T.any(String, Integer),
            value: 3.14
          )
        end.to raise_error(EasyTalk::ConstraintError, /String or Integer/)
      end
    end
  end
end
