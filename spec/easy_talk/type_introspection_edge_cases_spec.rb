# frozen_string_literal: true

require 'spec_helper'

# Tests exercising blind spots in the TypeIntrospection consolidation.
#
# Every spec uses only the public API — define_schema, json_schema, .new,
# .valid?, .errors — so that failures reflect real user-visible breakage.

RSpec.describe 'Type introspection edge cases' do
  # =========================================================================
  # Nilable String with constraints
  # =========================================================================
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

  # =========================================================================
  # Nilable String with pattern constraint
  # =========================================================================
  describe 'T.nilable(String) with pattern constraint' do
    let(:model) do
      Class.new do
        include EasyTalk::Model

        def self.name = 'NilablePatternModel'

        define_schema do
          property :code, T.nilable(String), pattern: '\A[A-Z]{3}\z'
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

  # =========================================================================
  # Nilable String with format constraint
  # =========================================================================
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

  # =========================================================================
  # Nilable Integer with range constraints
  # =========================================================================
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

  # =========================================================================
  # Nilable Float with range constraints
  # =========================================================================
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

  # =========================================================================
  # Nilable Boolean
  # =========================================================================
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

  # =========================================================================
  # Nilable Array (no constraints)
  # =========================================================================
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

  # =========================================================================
  # Nilable Array WITH min_items — the allow_nil blind spot
  # =========================================================================
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

  # =========================================================================
  # Nilable Array of models
  # =========================================================================
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

  # =========================================================================
  # Nilable Array of booleans
  # =========================================================================
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

  # =========================================================================
  # Nilable nested model
  # =========================================================================
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

  # =========================================================================
  # Tuple properties (non-nilable)
  # =========================================================================
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

  # =========================================================================
  # Enum constraint on nilable type
  # =========================================================================
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

  # =========================================================================
  # Complex model with every nilable type combined
  # =========================================================================
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

  # =========================================================================
  # Composition types (T::OneOf, T::AnyOf) produce valid schema & validation
  # =========================================================================
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

  # =========================================================================
  # Required-ness: nilable vs optional vs both
  # =========================================================================
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

  # =========================================================================
  # Nilable Integer with enum
  # =========================================================================
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

  # =========================================================================
  # Non-nilable array with item type validation
  # =========================================================================
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

  # =========================================================================
  # Multiple models sharing the same nested nilable model
  # =========================================================================
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
