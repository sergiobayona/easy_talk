require 'spec_helper'
require 'easy_talk/builders/base_builder'
require 'active_support/core_ext/hash/keys' # for assert_valid_keys

RSpec.describe EasyTalk::Builders::BaseBuilder do
  # A dummy type to simulate type-checking using recursively_valid?
  class DummyType
    def recursively_valid?(value)
      # Only "valid_value" is acceptable
      value == 'valid_value'
    end
  end

  let(:name)   { :dummy_property }
  let(:schema) { { type: 'object' } }

  context 'when initialized with valid options' do
    let(:options) { { title: 'A Title', description: 'A description', optional: false } }
    let(:builder) { described_class.new(name, schema.dup, options) }

    it 'sets name, schema, and options correctly' do
      expect(builder.name).to eq(name)
      expect(builder.schema).to eq(schema)
      expect(builder.options).to eq(options)
    end

    it 'merges common options and applies them in build' do
      # build should add keys to the schema using the mapping from COMMON_OPTIONS
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
      expect { described_class.new(name, schema, invalid_options) }
        .to raise_error(ArgumentError, /unknown key/i)
    end
  end

  context 'when an option value is nil' do
    let(:options) { { title: nil, description: 'Desc', optional: nil } }
    let(:builder) { described_class.new(name, schema.dup, options) }

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
    let(:builder) { described_class.new(name, schema.dup, custom_options, custom_valid_options) }

    it 'includes both common and custom valid options in the built schema' do
      result = builder.build
      expect(result).to include(
        title: 'A Title',
        custom_key: 'custom_value'
      )
    end
  end

  context 'when type checking via recursively_valid?' do
    let(:custom_valid_options) { { custom: { type: DummyType, key: :custom_key } } }

    context 'and the provided value does not pass recursively_valid?' do
      let(:custom_options) { { custom: 'invalid_value' } }
      let(:builder) { described_class.new(name, schema.dup, custom_options, custom_valid_options) }

      it 'raises a TypeError with a proper message' do
        expect { builder.build }
          .to raise_error(TypeError, /Invalid type for custom/)
      end
    end

    context 'and the provided value passes recursively_valid?' do
      let(:custom_options) { { custom: 'valid_value' } }
      let(:builder) { described_class.new(name, schema.dup, custom_options, custom_valid_options) }

      it 'includes the custom option in the built schema' do
        result = builder.build
        expect(result).to include(custom_key: 'valid_value')
      end
    end
  end

  describe '.collection_type?' do
    it 'returns false' do
      expect(described_class.collection_type?).to eq(false)
    end
  end
end
