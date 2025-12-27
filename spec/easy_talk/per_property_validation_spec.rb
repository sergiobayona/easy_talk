# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Per-property validation control' do
  describe 'property with validate: false' do
    let(:test_class) do
      Class.new do
        include EasyTalk::Model

        def self.name = 'PerPropertyValidationModel'

        define_schema do
          property :validated_field, String, min_length: 5
          property :unvalidated_field, String, min_length: 5, validate: false
        end
      end
    end

    it 'validates fields without validate: false' do
      instance = test_class.new(validated_field: 'X', unvalidated_field: 'OK')
      expect(instance.valid?).to be false
      expect(instance.errors[:validated_field]).not_to be_empty
    end

    it 'skips validation for fields with validate: false' do
      instance = test_class.new(validated_field: 'ValidName', unvalidated_field: 'X')
      expect(instance.valid?).to be true
      expect(instance.errors[:unvalidated_field]).to be_empty
    end

    it 'still includes unvalidated field in schema' do
      schema = test_class.json_schema

      expect(schema['properties']['unvalidated_field']).to be_present
      expect(schema['properties']['unvalidated_field']['minLength']).to eq(5)
    end

    it 'still includes unvalidated field in required array' do
      schema = test_class.json_schema
      expect(schema['required']).to include('unvalidated_field')
    end
  end

  describe 'mixing validated and unvalidated properties' do
    let(:test_class) do
      Class.new do
        include EasyTalk::Model

        def self.name = 'MixedValidationModel'

        define_schema do
          property :name, String, min_length: 2
          property :email, String, format: 'email'
          property :legacy_id, String, pattern: '^\d+$', validate: false
          property :age, Integer, minimum: 0
          property :notes, String, max_length: 1000, validate: false
        end
      end
    end

    it 'validates only properties without validate: false' do
      instance = test_class.new(
        name: 'Jo',
        email: 'valid@example.com',
        legacy_id: 'not-a-number', # Would fail pattern but validate: false
        age: 25,
        notes: 'A' * 2000 # Would fail max_length but validate: false
      )

      expect(instance.valid?).to be true
    end

    it 'fails validation on validated properties' do
      instance = test_class.new(
        name: 'X', # Too short
        email: 'invalid',
        legacy_id: 'anything',
        age: -5, # Negative
        notes: 'anything'
      )

      expect(instance.valid?).to be false
      expect(instance.errors[:name]).not_to be_empty
      expect(instance.errors[:email]).not_to be_empty
      expect(instance.errors[:age]).not_to be_empty
      expect(instance.errors[:legacy_id]).to be_empty
      expect(instance.errors[:notes]).to be_empty
    end
  end

  describe 'validate: false with different types' do
    context 'with Integer type' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'IntegerValidateTest'

          define_schema do
            property :score, Integer, minimum: 0, maximum: 100, validate: false
          end
        end
      end

      it 'does not validate integer constraints' do
        instance = test_class.new(score: -100)
        expect(instance.valid?).to be true
      end
    end

    context 'with enum constraint' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'EnumValidateTest'

          define_schema do
            property :status, String, enum: %w[active inactive], validate: false
          end
        end
      end

      it 'does not validate enum constraint' do
        instance = test_class.new(status: 'unknown')
        expect(instance.valid?).to be true
      end
    end

    context 'with boolean type' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'BooleanValidateTest'

          define_schema do
            property :active, T::Boolean, validate: false
          end
        end
      end

      it 'does not validate boolean type' do
        instance = test_class.new(active: 'yes')
        expect(instance.valid?).to be true
      end
    end
  end

  describe 'validate: false does not skip presence for required fields' do
    let(:test_class) do
      Class.new do
        include EasyTalk::Model

        def self.name = 'PresenceSkipTest'

        define_schema do
          property :required_field, String, validate: false
        end
      end
    end

    it 'still does not add presence validation when validate: false' do
      instance = test_class.new(required_field: nil)
      # With validate: false, no validations are added at all
      expect(instance.valid?).to be true
    end
  end

  describe 'validate: false with optional properties' do
    let(:test_class) do
      Class.new do
        include EasyTalk::Model

        def self.name = 'OptionalValidateTest'

        define_schema do
          property :name, String, min_length: 5, optional: true, validate: false
        end
      end
    end

    it 'skips all validation' do
      instance = test_class.new(name: 'X')
      expect(instance.valid?).to be true

      instance = test_class.new(name: nil)
      expect(instance.valid?).to be true
    end

    it 'excludes from required in schema' do
      schema = test_class.json_schema
      expect(schema['required'] || []).not_to include('name')
    end
  end
end
