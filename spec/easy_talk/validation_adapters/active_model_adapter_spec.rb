# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::ValidationAdapters::ActiveModelAdapter do
  describe '.build_validations' do
    context 'with string constraints' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'StringTest'

          define_schema do
            property :name, String, min_length: 2, max_length: 10
          end
        end
      end

      it 'applies length validations' do
        instance = test_class.new(name: 'X')
        expect(instance.valid?).to be false
        expect(instance.errors[:name]).to include('is too short (minimum is 2 characters)')

        instance = test_class.new(name: 'A' * 11)
        expect(instance.valid?).to be false
        expect(instance.errors[:name]).to include('is too long (maximum is 10 characters)')

        instance = test_class.new(name: 'Valid')
        expect(instance.valid?).to be true
      end
    end

    context 'with format constraints' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'EmailTest'

          define_schema do
            property :email, String, format: 'email'
          end
        end
      end

      it 'applies format validations' do
        instance = test_class.new(email: 'invalid')
        expect(instance.valid?).to be false
        expect(instance.errors[:email]).to include('must be a valid email address')

        instance = test_class.new(email: 'test@example.com')
        expect(instance.valid?).to be true
      end
    end

    context 'with integer constraints' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'IntegerTest'

          define_schema do
            property :age, Integer, minimum: 0, maximum: 120
          end
        end
      end

      it 'applies numericality validations' do
        instance = test_class.new(age: -1)
        expect(instance.valid?).to be false

        instance = test_class.new(age: 121)
        expect(instance.valid?).to be false

        instance = test_class.new(age: 25)
        expect(instance.valid?).to be true
      end
    end

    context 'with enum constraints' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'EnumTest'

          define_schema do
            property :status, String, enum: %w[active inactive pending]
          end
        end
      end

      it 'applies inclusion validations' do
        instance = test_class.new(status: 'unknown')
        expect(instance.valid?).to be false
        expect(instance.errors[:status]).to include('must be one of: active, inactive, pending')

        instance = test_class.new(status: 'active')
        expect(instance.valid?).to be true
      end
    end

    context 'with boolean type' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'BooleanTest'

          define_schema do
            property :active, T::Boolean
          end
        end
      end

      it 'applies boolean validations' do
        instance = test_class.new(active: 'yes')
        expect(instance.valid?).to be false

        instance = test_class.new(active: true)
        expect(instance.valid?).to be true

        instance = test_class.new(active: false)
        expect(instance.valid?).to be true
      end
    end

    context 'with presence validation' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'PresenceTest'

          define_schema do
            property :name, String
          end
        end
      end

      it 'requires the field to be present' do
        instance = test_class.new(name: nil)
        expect(instance.valid?).to be false
        expect(instance.errors[:name]).to include("can't be blank")

        instance = test_class.new(name: 'Present')
        expect(instance.valid?).to be true
      end
    end

    context 'with optional property' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'OptionalTest'

          define_schema do
            property :name, String, optional: true
          end
        end
      end

      it 'allows nil values' do
        instance = test_class.new(name: nil)
        expect(instance.valid?).to be true
      end
    end
  end
end
