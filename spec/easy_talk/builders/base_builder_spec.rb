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
    value.to_s == "valid_value"
  end
end

RSpec.describe EasyTalk::Builders::BaseBuilder do
  let(:name)   { :dummy_property }
  let(:schema) { { type: 'object' } }

  context "when initialized with valid common options" do
    let(:options) { { title: "A Title", description: "A description", optional: false } }
    let(:builder) { described_class.new(name, schema.dup, options) }

    it "sets name, schema, and options correctly" do
      expect(builder.name).to eq(name)
      expect(builder.schema).to eq(schema)
      expect(builder.options).to eq(options)
    end

    it "merges common options and applies them in build" do
      # The build method should add keys to the schema using COMMON_OPTIONS mapping.
      result = builder.build
      expect(result).to include(
        type: 'object',
        title: "A Title",
        description: "A description",
        optional: false
      )
    end
  end

  context "when initialized with unknown option keys" do
    let(:invalid_options) { { unknown: "value" } }
    it "raises an ArgumentError" do
      expect { described_class.new(name, schema, invalid_options) }
        .to raise_error(ArgumentError, /unknown key/i)
    end
  end

  context "when an option value is nil" do
    let(:options) { { title: nil, description: "Desc", optional: nil } }
    let(:builder) { described_class.new(name, schema.dup, options) }

    it "skips nil values in build" do
      result = builder.build
      expect(result).not_to have_key(:title)
      expect(result).to include(description: "Desc")
      expect(result).not_to have_key(:optional)
    end
  end

  context "when extending valid_options with a custom option" do
    let(:custom_options) { { custom: "custom_value", title: "A Title" } }
    let(:custom_valid_options) { { custom: { type: String, key: :custom_key } } }
    let(:builder) { described_class.new(name, schema.dup, custom_options, custom_valid_options) }

    it "includes both common and custom valid options in the built schema" do
      result = builder.build
      expect(result).to include(
        title: "A Title",
        custom_key: "custom_value"
      )
    end
  end

  context "when type checking via recursively_valid?" do
    # Use DummyType (a subclass of String) as the type constraint.
    let(:custom_valid_options) { { custom: { type: DummyType, key: :custom_key } } }

    context "and the provided value does not pass recursively_valid?" do
      # Here we pass a value that is an instance of DummyType but with invalid content.
      let(:custom_options) { { custom: DummyType.new("invalid_value") } }
      let(:builder) { described_class.new(name, schema.dup, custom_options, custom_valid_options) }

      it "raises a TypeError with a proper message" do
        expect { builder.build }
          .to raise_error(TypeError, /Invalid type for custom/)
      end
    end

    context "and the provided value passes recursively_valid?" do
      # Pass an instance of DummyType whose value is "valid_value".
      let(:custom_options) { { custom: DummyType.new("valid_value") } }
      let(:builder) { described_class.new(name, schema.dup, custom_options, custom_valid_options) }

      it "includes the custom option in the built schema" do
        result = builder.build
        expect(result).to include(custom_key: DummyType.new("valid_value"))
      end
    end
  end

  context "when the valid option is an array type" do
    context "with T::Array[String] and a valid array" do
      let(:custom_valid_options) { { array_option: { type: T::Array[String], key: :array_key } } }
      let(:options) { { array_option: ["a", "b", "c"] } }
      let(:builder) { described_class.new(name, schema.dup, options, custom_valid_options) }

      it "includes the array option in the built schema" do
        result = builder.build
        expect(result).to include(array_key: ["a", "b", "c"])
      end
    end

    context "with T::Array[String] and an invalid array" do
      let(:custom_valid_options) { { array_option: { type: T::Array[String], key: :array_key } } }
      let(:options) { { array_option: ["a", 2, "c"] } }
      let(:builder) { described_class.new(name, schema.dup, options, custom_valid_options) }

      it "raises a TypeError with a proper message" do
        expect { builder.build }
          .to raise_error(TypeError, /Invalid type for array_option/)
      end
    end

    context "with T::Array[Integer] and a valid array" do
      let(:custom_valid_options) { { int_array: { type: T::Array[Integer], key: :int_array_key } } }
      let(:options) { { int_array: [1, 2, 3] } }
      let(:builder) { described_class.new(name, schema.dup, options, custom_valid_options) }

      it "includes the integer array option in the built schema" do
        result = builder.build
        expect(result).to include(int_array_key: [1, 2, 3])
      end
    end

    context "with T::Array[Integer] and an invalid array" do
      let(:custom_valid_options) { { int_array: { type: T::Array[Integer], key: :int_array_key } } }
      let(:options) { { int_array: [1, "2", 3] } }
      let(:builder) { described_class.new(name, schema.dup, options, custom_valid_options) }

      it "raises a TypeError with a proper message" do
        expect { builder.build }
          .to raise_error(TypeError, /Invalid type for int_array/)
      end
    end
  end

  describe ".collection_type?" do
    it "returns false" do
      expect(described_class.collection_type?).to eq(false)
    end
  end
end
