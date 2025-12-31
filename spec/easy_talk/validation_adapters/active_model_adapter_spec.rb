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

    context 'with required T::Array[String] property' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'ArrayTest'

          define_schema do
            property :tags, T::Array[String]
          end
        end
      end

      it 'validates empty arrays as valid' do
        instance = test_class.new(tags: [])
        expect(instance.valid?).to be true
      end

      it 'validates non-empty arrays as valid' do
        instance = test_class.new(tags: %w[ruby rails])
        expect(instance.valid?).to be true
      end

      it 'rejects nil for required array properties' do
        instance = test_class.new(tags: nil)
        expect(instance.valid?).to be false
        expect(instance.errors[:tags]).to include("can't be blank")
      end
    end

    context 'with optional T::Array[String] property' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'OptionalArrayTest'

          define_schema do
            property :tags, T::Array[String], optional: true
          end
        end
      end

      it 'allows nil for optional array properties' do
        instance = test_class.new(tags: nil)
        expect(instance.valid?).to be true
      end

      it 'validates empty arrays as valid' do
        instance = test_class.new(tags: [])
        expect(instance.valid?).to be true
      end
    end

    context 'with T::Array[EasyTalk::Model] nested validation' do
      let(:address_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'Address'

          define_schema do
            property :street, String
            property :city, String
          end
        end
      end

      let(:person_class) do
        address = address_class
        Class.new do
          include EasyTalk::Model

          def self.name = 'Person'

          define_schema do
            property :name, String
            property :addresses, T::Array[address]
          end
        end
      end

      before do
        stub_const('Address', address_class)
        stub_const('Person', person_class)
      end

      it 'validates nested models in arrays' do
        person = Person.new(
          name: 'John',
          addresses: [
            Address.new(street: '123 Main St', city: 'Boston')
          ]
        )
        expect(person.valid?).to be true
      end

      it 'reports errors for invalid nested models with indexed paths' do
        person = Person.new(
          name: 'John',
          addresses: [
            Address.new(street: '', city: '')
          ]
        )
        expect(person.valid?).to be false
        expect(person.errors[:'addresses[0].street']).to include("can't be blank")
        expect(person.errors[:'addresses[0].city']).to include("can't be blank")
      end

      it 'reports errors only for invalid items in mixed arrays' do
        person = Person.new(
          name: 'John',
          addresses: [
            Address.new(street: '123 Main St', city: 'Boston'),
            Address.new(street: '', city: 'NYC'),
            Address.new(street: '456 Oak Ave', city: '')
          ]
        )
        expect(person.valid?).to be false
        expect(person.errors.attribute_names).not_to include(:'addresses[0].street')
        expect(person.errors.attribute_names).not_to include(:'addresses[0].city')
        expect(person.errors[:'addresses[1].street']).to include("can't be blank")
        expect(person.errors[:'addresses[2].city']).to include("can't be blank")
      end

      it 'validates empty arrays as valid' do
        person = Person.new(name: 'John', addresses: [])
        expect(person.valid?).to be true
      end

      it 'rejects nil for required array properties' do
        person = Person.new(name: 'John', addresses: nil)
        expect(person.valid?).to be false
        expect(person.errors[:addresses]).to include("can't be blank")
      end

      it 'auto-instantiates hash items as model instances' do
        person = Person.new(
          name: 'John',
          addresses: [
            { street: '123 Main St', city: 'Boston' }
          ]
        )
        expect(person.addresses.first).to be_a(Address)
        expect(person.valid?).to be true
      end

      it 'auto-instantiates and validates invalid hash items' do
        person = Person.new(
          name: 'John',
          addresses: [
            { street: '', city: '' }
          ]
        )
        expect(person.addresses.first).to be_a(Address)
        expect(person.valid?).to be false
        expect(person.errors[:'addresses[0].street']).to include("can't be blank")
      end
    end

    context 'with T.nilable(T::Array[EasyTalk::Model]) nested validation' do
      let(:address_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'Address'

          define_schema do
            property :street, String
            property :city, String
          end
        end
      end

      let(:employee_class) do
        address = address_class
        Class.new do
          include EasyTalk::Model

          def self.name = 'Employee'

          define_schema do
            property :name, String
            property :addresses, T.nilable(T::Array[address])
          end
        end
      end

      before do
        stub_const('Address', address_class)
        stub_const('Employee', employee_class)
      end

      it 'allows nil for nilable array property' do
        employee = Employee.new(name: 'John', addresses: nil)
        expect(employee.valid?).to be true
      end

      it 'validates nested models in nilable arrays' do
        employee = Employee.new(
          name: 'John',
          addresses: [
            Address.new(street: '', city: '')
          ]
        )
        expect(employee.valid?).to be false
        expect(employee.errors[:'addresses[0].street']).to include("can't be blank")
      end

      it 'auto-instantiates hash items in nilable arrays' do
        employee = Employee.new(
          name: 'John',
          addresses: [
            { street: '123 Main St', city: 'Boston' }
          ]
        )
        expect(employee.addresses.first).to be_a(Address)
        expect(employee.valid?).to be true
      end
    end
  end
end
