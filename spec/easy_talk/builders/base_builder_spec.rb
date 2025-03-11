# frozen_string_literal: true

require 'spec_helper'
require 'easy_talk/builders/base_builder'
require 'active_support/core_ext/hash/keys'
require 'sorbet-runtime'

# Define a dummy type as a subclass of String. This allows us to use T.let
# and have our custom type check work. It also defines a class method
# `recursively_valid?` that checks the value.
class DummyType < String
  def self.recursively_valid?(value)
    # Accept the value if its string representation equals "valid_value"
    value.to_s == 'valid_value'
  end
end

RSpec.describe EasyTalk::Builders::BaseBuilder do
  let(:property_name) { :dummy_property }
  let(:schema) { { type: 'object' } }

  context 'when initialized with valid common options' do
    let(:options) { { title: 'A Title', description: 'A description', optional: false } }
    let(:builder) { described_class.new(property_name, schema.dup, options) }

    it 'sets property_name, schema, and options correctly' do
      expect(builder.property_name).to eq(property_name)
      expect(builder.schema).to eq(schema)
      expect(builder.options).to eq(options)
    end

    it 'merges common options and applies them in build' do
      # The build method should add keys to the schema using COMMON_OPTIONS mapping.
      result = builder.build
      expect(result).to include(
        type: 'object',
        title: 'A Title',
        description: 'A description',
        optional: false
      )
    end
  end

  context 'when initialized with unknown option keys' do
    let(:invalid_options) { { unknown: 'value' } }

    it 'raises an ArgumentError' do
      expect { described_class.new(property_name, schema, invalid_options) }
        .to raise_error(EasyTalk::UnknownOptionError, /Unknown option 'unknown' for property 'dummy_property'/i)
    end
  end

  context 'when an option value is nil' do
    let(:options) { { title: nil, description: 'Desc', optional: nil } }
    let(:builder) { described_class.new(property_name, schema.dup, options) }

    it 'skips nil values in build' do
      result = builder.build
      expect(result).not_to have_key(:title)
      expect(result).to include(description: 'Desc')
      expect(result).not_to have_key(:optional)
    end
  end

  context 'when extending valid_options with a custom option' do
    let(:custom_options) { { custom: 'custom_value', title: 'A Title' } }
    let(:custom_valid_options) { { custom: { type: String, key: :custom_key } } }
    let(:builder) { described_class.new(property_name, schema.dup, custom_options, custom_valid_options) }

    it 'includes both common and custom valid options in the built schema' do
      result = builder.build
      expect(result).to include(
        title: 'A Title',
        custom_key: 'custom_value'
      )
    end
  end

  context 'when the valid option is an array type' do
    context 'with T::Array[String] and a valid array' do
      let(:custom_valid_options) { { array_option: { type: T::Array[String], key: :array_key } } }
      let(:options) { { array_option: %w[a b c] } }
      let(:builder) { described_class.new(property_name, schema.dup, options, custom_valid_options) }

      it 'includes the array option in the built schema' do
        result = builder.build
        expect(result).to include(array_key: %w[a b c])
      end
    end

    context 'with T::Array[String] and an invalid array' do
      let(:custom_valid_options) { { array_option: { type: T::Array[String], key: :array_key } } }
      let(:options) { { array_option: ['a', 2, 'c'] } }
      let(:builder) { described_class.new(property_name, schema.dup, options, custom_valid_options) }

      it 'raises a TypeError with a proper message' do
        expect { builder.build }
          .to raise_error(EasyTalk::ConstraintError, "Error in property 'dummy_property': Constraint 'array_option' at index 1 expects String, but received 2 (Integer).")
      end
    end

    context 'with T::Array[Integer] and a valid array' do
      let(:custom_valid_options) { { int_array: { type: T::Array[Integer], key: :int_array_key } } }
      let(:options) { { int_array: [1, 2, 3] } }
      let(:builder) { described_class.new(property_name, schema.dup, options, custom_valid_options) }

      it 'includes the integer array option in the built schema' do
        result = builder.build
        expect(result).to include(int_array_key: [1, 2, 3])
      end
    end

    context 'with T::Array[Integer] and an invalid array' do
      let(:custom_valid_options) { { int_array: { type: T::Array[Integer], key: :int_array_key } } }
      let(:options) { { int_array: [1, '2', 3] } }
      let(:builder) { described_class.new(property_name, schema.dup, options, custom_valid_options) }

      it 'raises a TypeError with a proper message' do
        expect { builder.build }
          .to raise_error(EasyTalk::ConstraintError, "Error in property 'dummy_property': Constraint 'int_array' at index 1 expects Integer, but received \"2\" (String).")
      end
    end
  end

  describe '.collection_type?' do
    it 'returns false' do
      expect(described_class.collection_type?).to be(false)
    end
  end
end
