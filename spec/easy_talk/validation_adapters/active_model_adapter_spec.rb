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

    context 'with url format constraints' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'UrlTest'

          define_schema do
            property :website, String, format: 'url'
          end
        end
      end

      it 'validates url format' do
        instance = test_class.new(website: 'not a url')
        expect(instance.valid?).to be false
        expect(instance.errors[:website]).to include('must be a valid URL')

        instance = test_class.new(website: 'foo http://example.com bar')
        expect(instance.valid?).to be false
        expect(instance.errors[:website]).to include('must be a valid URL')

        instance = test_class.new(website: 'http://example.com/%')
        expect(instance.valid?).to be false
        expect(instance.errors[:website]).to include('must be a valid URL')

        instance = test_class.new(website: 'https://example.com/path?query=1')
        expect(instance.valid?).to be true
      end
    end

    context 'with uri format constraints' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'UriTest'

          define_schema do
            property :resource, String, format: 'uri'
          end
        end
      end

      it 'validates uri format' do
        instance = test_class.new(resource: 'not a uri')
        expect(instance.valid?).to be false
        expect(instance.errors[:resource]).to include('must be a valid URL')

        instance = test_class.new(resource: 'mailto:test@example.com')
        expect(instance.valid?).to be true
      end
    end

    context 'with time format constraints when Time.zone is nil' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'TimeFormatTest'

          define_schema do
            property :start_time, String, format: 'time'
          end
        end
      end

      around do |example|
        next example.run unless Time.respond_to?(:zone=)

        original_zone = Time.zone
        Time.zone = nil
        example.run
      ensure
        Time.zone = original_zone
      end

      it 'does not raise when Time.zone is nil' do
        instance = test_class.new(start_time: '12:34:56')
        expect { instance.valid? }.not_to raise_error
        expect(instance.errors[:start_time]).to be_empty
      end

      it 'adds an error for invalid time strings' do
        instance = test_class.new(start_time: 'not-a-time')
        expect { instance.valid? }.not_to raise_error
        expect(instance.errors[:start_time]).to include('must be a valid time in HH:MM:SS format')
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

      # Per JSON Schema: optional means the property can be omitted from the object,
      # but if present, null is still invalid unless type includes null
      it 'rejects nil for optional non-nilable array properties' do
        instance = test_class.new(tags: nil)
        expect(instance.valid?).to be false
        expect(instance.errors[:tags]).to include("can't be blank")
      end

      it 'validates empty arrays as valid' do
        instance = test_class.new(tags: [])
        expect(instance.valid?).to be true
      end
    end

    context 'with optional T.nilable(T::Array[String]) property' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'OptionalNilableArrayTest'

          define_schema do
            property :tags, T.nilable(T::Array[String]), optional: true
          end
        end
      end

      it 'allows nil for optional nilable array properties' do
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

  describe 'URI format implementation' do
    it 'does not emit RFC3986 make_regexp obsolete warnings when requiring the gem' do
      require 'open3'
      require 'rbconfig'

      _stdout, stderr, status = Open3.capture3(
        RbConfig.ruby,
        '-w',
        '-rbundler/setup',
        '-Ilib',
        '-e',
        'require "easy_talk"'
      )

      expect(status.success?).to be true
      expect(stderr).not_to include('URI::RFC3986_PARSER.make_regexp is obsolete')
    end

    it 'validates URI by parsing (full string)' do
      klass = Class.new do
        include EasyTalk::Model

        def self.name = 'UriParsingTest'

        define_schema do
          property :resource, String, format: 'uri'
        end
      end

      instance = klass.new(resource: 'foo http://example.com bar')
      expect(instance.valid?).to be false
      expect(instance.errors[:resource]).to include('must be a valid URL')

      instance = klass.new(resource: 'http://example.com/%')
      expect(instance.valid?).to be false
      expect(instance.errors[:resource]).to include('must be a valid URL')

      instance = klass.new(resource: 'mailto:test@example.com')
      expect(instance.valid?).to be true
    end
  end

  describe '.build_schema_validations' do
    describe 'min_properties' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'MinPropertiesTest'

          define_schema do
            min_properties 2
            property :name, String, optional: true
            property :email, String, optional: true
            property :phone, String, optional: true
          end
        end
      end

      it 'fails validation when fewer than min_properties are present' do
        instance = test_class.new(name: 'John')
        expect(instance.valid?).to be false
        expect(instance.errors[:base]).to include('must have at least 2 properties present')
      end

      it 'passes validation when exactly min_properties are present' do
        instance = test_class.new(name: 'John', email: 'john@example.com')
        expect(instance.valid?).to be true
      end

      it 'passes validation when more than min_properties are present' do
        instance = test_class.new(name: 'John', email: 'john@example.com', phone: '555-1234')
        expect(instance.valid?).to be true
      end

      it 'counts false as a present value' do
        bool_test_class = Class.new do
          include EasyTalk::Model

          def self.name = 'BoolMinPropsTest'

          define_schema do
            min_properties 2
            property :active, T::Boolean, optional: true
            property :verified, T::Boolean, optional: true
          end
        end

        instance = bool_test_class.new(active: false, verified: false)
        expect(instance.valid?).to be true
      end
    end

    describe 'max_properties' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'MaxPropertiesTest'

          define_schema do
            max_properties 2
            property :name, String, optional: true
            property :email, String, optional: true
            property :phone, String, optional: true
          end
        end
      end

      it 'fails validation when more than max_properties are present' do
        instance = test_class.new(name: 'John', email: 'john@example.com', phone: '555-1234')
        expect(instance.valid?).to be false
        expect(instance.errors[:base]).to include('must have at most 2 properties present')
      end

      it 'passes validation when exactly max_properties are present' do
        instance = test_class.new(name: 'John', email: 'john@example.com')
        expect(instance.valid?).to be true
      end

      it 'passes validation when fewer than max_properties are present' do
        instance = test_class.new(name: 'John')
        expect(instance.valid?).to be true
      end
    end

    describe 'min_properties and max_properties combined' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'MinMaxPropertiesTest'

          define_schema do
            min_properties 1
            max_properties 2
            property :name, String, optional: true
            property :email, String, optional: true
            property :phone, String, optional: true
          end
        end
      end

      it 'fails when below minimum' do
        instance = test_class.new
        expect(instance.valid?).to be false
        expect(instance.errors[:base]).to include('must have at least 1 property present')
      end

      it 'fails when above maximum' do
        instance = test_class.new(name: 'John', email: 'john@example.com', phone: '555-1234')
        expect(instance.valid?).to be false
        expect(instance.errors[:base]).to include('must have at most 2 properties present')
      end

      it 'passes when within range' do
        instance = test_class.new(name: 'John', email: 'john@example.com')
        expect(instance.valid?).to be true
      end
    end

    describe 'dependent_required' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'DependentRequiredTest'

          define_schema do
            property :credit_card, String, optional: true
            property :billing_address, String, optional: true
            property :security_code, String, optional: true
            dependent_required('credit_card' => %w[billing_address security_code])
          end
        end
      end

      it 'passes when trigger property is not present' do
        instance = test_class.new(billing_address: '123 Main St')
        expect(instance.valid?).to be true
      end

      it 'fails when trigger is present but dependent property is missing' do
        instance = test_class.new(credit_card: '4111111111111111')
        expect(instance.valid?).to be false
        expect(instance.errors[:billing_address]).to include('is required when credit_card is present')
        expect(instance.errors[:security_code]).to include('is required when credit_card is present')
      end

      it 'fails when trigger is present but one dependent property is missing' do
        instance = test_class.new(credit_card: '4111111111111111', billing_address: '123 Main St')
        expect(instance.valid?).to be false
        expect(instance.errors[:billing_address]).to be_empty
        expect(instance.errors[:security_code]).to include('is required when credit_card is present')
      end

      it 'passes when trigger and all dependent properties are present' do
        instance = test_class.new(
          credit_card: '4111111111111111',
          billing_address: '123 Main St',
          security_code: '123'
        )
        expect(instance.valid?).to be true
      end

      it 'handles boolean trigger values correctly' do
        bool_dep_class = Class.new do
          include EasyTalk::Model

          def self.name = 'BoolDependentTest'

          define_schema do
            property :is_business, T::Boolean, optional: true
            property :company_name, String, optional: true
            dependent_required('is_business' => ['company_name'])
          end
        end

        # false is considered "present" so dependencies should be checked
        instance = bool_dep_class.new(is_business: false)
        expect(instance.valid?).to be false
        expect(instance.errors[:company_name]).to include('is required when is_business is present')

        instance = bool_dep_class.new(is_business: false, company_name: 'Acme Inc')
        expect(instance.valid?).to be true
      end

      it 'handles multiple dependency rules' do
        multi_dep_class = Class.new do
          include EasyTalk::Model

          def self.name = 'MultiDependentTest'

          define_schema do
            property :name, String, optional: true
            property :email, String, optional: true
            property :phone, String, optional: true
            dependent_required(
              'name' => ['email'],
              'email' => ['phone']
            )
          end
        end

        instance = multi_dep_class.new(name: 'John')
        expect(instance.valid?).to be false
        expect(instance.errors[:email]).to include('is required when name is present')

        instance = multi_dep_class.new(name: 'John', email: 'john@example.com')
        expect(instance.valid?).to be false
        expect(instance.errors[:phone]).to include('is required when email is present')

        instance = multi_dep_class.new(name: 'John', email: 'john@example.com', phone: '555-1234')
        expect(instance.valid?).to be true
      end
    end
  end
end
