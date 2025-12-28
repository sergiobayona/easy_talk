# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Schema Validation Matcher' do
  let(:address_class) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'Address'
      end

      define_schema do
        property :street, String
        property :city, String
        property :state, String
        property :zip, String
      end
    end
  end

  let(:employee_class) do
    address = address_class
    Class.new do
      include EasyTalk::Model

      def self.name
        'Employee'
      end

      define_schema do
        property :name, String
        property :gender, String, enum: %w[male female other]
        property :department, T.nilable(String)
        property :active, T::Boolean, default: true
        property :addresses, T.nilable(T::Array[address])
      end
    end
  end

  before do
    stub_const('Address', address_class)
    stub_const('Employee', employee_class)
  end

  describe 'validate_schema_for matcher' do
    context 'with valid data' do
      it 'passes when data matches schema' do
        expect(Employee).to validate_schema_for(
          name: 'John Doe',
          gender: 'male',
          department: 'Engineering',
          active: true,
          addresses: [
            { street: '123 Main St', city: 'Boston', state: 'MA', zip: '02101' }
          ]
        )
      end

      it 'passes with nil for nilable properties' do
        expect(Employee).to validate_schema_for(
          name: 'Jane Doe',
          gender: 'female',
          department: nil,
          active: true,
          addresses: nil
        )
      end

      it 'passes with empty array for array properties' do
        expect(Employee).to validate_schema_for(
          name: 'Bob Smith',
          gender: 'male',
          department: nil,
          active: false,
          addresses: []
        )
      end
    end

    context 'with invalid data' do
      it 'fails when enum value is invalid' do
        expect(Employee).not_to validate_schema_for(
          name: 'Invalid Gender',
          gender: 'invalid_value',
          department: nil,
          active: true,
          addresses: nil
        )
      end

      it 'fails when required field is missing' do
        expect(Employee).not_to validate_schema_for(
          gender: 'male',
          department: nil,
          active: true,
          addresses: nil
        )
      end

      it 'fails when boolean field has wrong type' do
        expect(Employee).not_to validate_schema_for(
          name: 'Test',
          gender: 'male',
          department: nil,
          active: 'not_a_boolean',
          addresses: nil
        )
      end

      it 'fails when array contains wrong type' do
        expect(Employee).not_to validate_schema_for(
          name: 'Test',
          gender: 'male',
          department: nil,
          active: true,
          addresses: ['not an object']
        )
      end
    end
  end

  describe 'have_matching_validations_for matcher' do
    context 'when validations agree' do
      it 'passes for valid data' do
        expect(Employee).to have_matching_validations_for(
          name: 'John Doe',
          gender: 'male',
          department: 'Engineering',
          active: true,
          addresses: nil
        )
      end

      it 'passes for invalid enum value' do
        expect(Employee).to have_matching_validations_for(
          name: 'Jane Doe',
          gender: 'invalid_gender',
          department: nil,
          active: true,
          addresses: nil
        )
      end

      it 'passes for nil boolean (both catch it)' do
        expect(Employee).to have_matching_validations_for(
          name: 'Test User',
          gender: 'male',
          department: nil,
          active: nil,
          addresses: nil
        )
      end
    end

    context 'when validations disagree (known gaps)', :known_gap do
      it 'detects mismatch for empty string (schema valid, ActiveModel invalid)' do
        # JSON Schema type: "string" allows empty strings
        # ActiveModel presence: true rejects empty strings
        expect(Employee).not_to have_matching_validations_for(
          name: '',
          gender: 'male',
          department: nil,
          active: true,
          addresses: nil
        )
      end

      it 'detects mismatch for array with wrong type (schema invalid, ActiveModel valid)' do
        # JSON Schema catches type mismatch in array items
        # ActiveModel doesn't validate array item types for T.nilable(T::Array[Model])
        expect(Employee).not_to have_matching_validations_for(
          name: 'Test',
          gender: 'male',
          department: nil,
          active: true,
          addresses: ['not an object']
        )
      end
    end
  end

  describe 'schema_validation_result helper' do
    it 'provides detailed validation information' do
      result = schema_validation_result(Employee, {
                                          name: 'Test',
                                          gender: 'invalid',
                                          department: nil,
                                          active: true,
                                          addresses: nil
                                        })

      expect(result.schema_valid?).to be false
      expect(result.schema_error_pointers).to include('/gender')
      expect(result.schema_error_types).to include('enum')

      expect(result.active_model_valid?).to be false
      expect(result.active_model_error_attributes).to include(:gender)
    end

    it 'provides formatted errors for API responses' do
      result = schema_validation_result(Employee, {
                                          name: '',
                                          gender: 'invalid',
                                          department: nil,
                                          active: nil,
                                          addresses: nil
                                        })

      formatted = result.formatted_errors
      expect(formatted).to be_an(Array)
      expect(formatted.first).to include('field', 'message')
    end

    it 'exposes validations_match? for checking alignment' do
      # Valid data - both should agree
      valid_result = schema_validation_result(Employee, {
                                                name: 'John',
                                                gender: 'male',
                                                department: nil,
                                                active: true,
                                                addresses: nil
                                              })
      expect(valid_result.validations_match?).to be true

      # Invalid enum - both should agree
      invalid_result = schema_validation_result(Employee, {
                                                  name: 'John',
                                                  gender: 'invalid',
                                                  department: nil,
                                                  active: true,
                                                  addresses: nil
                                                })
      expect(invalid_result.validations_match?).to be true
    end
  end

  describe 'nested model validation in arrays' do
    context 'T.nilable(T::Array[Model]) with invalid nested data' do
      let(:invalid_nested_data) do
        {
          name: 'Test User',
          gender: 'male',
          department: nil,
          active: true,
          addresses: [
            { street: '', city: '', state: '', zip: '' }
          ]
        }
      end

      it 'JSON Schema considers empty nested object fields valid (no minLength constraint)' do
        # JSON Schema type: "string" allows empty strings - this is expected behavior
        expect(Employee).to validate_schema_for(invalid_nested_data)
      end

      it 'ActiveModel now validates nested models in arrays (issue #112 fixed)' do
        # Issue #112 is now fixed - nested models in arrays are recursively validated
        employee = Employee.new(invalid_nested_data)
        expect(employee.valid?).to be false
        expect(employee.errors.attribute_names).to include(:'addresses[0].street')
        expect(employee.errors.attribute_names).to include(:'addresses[0].city')
      end

      it 'validators now disagree on empty strings (semantic difference)', :known_gap do
        # JSON Schema allows empty strings (type: "string")
        # ActiveModel rejects empty strings (presence: true)
        # This is a known semantic difference, not a bug
        expect(Employee).not_to have_matching_validations_for(invalid_nested_data)
      end
    end

    context 'with valid nested data' do
      let(:valid_nested_data) do
        {
          name: 'Test User',
          gender: 'male',
          department: nil,
          active: true,
          addresses: [
            { street: '123 Main St', city: 'Boston', state: 'MA', zip: '02101' }
          ]
        }
      end

      it 'both validators agree valid data is valid' do
        expect(Employee).to have_matching_validations_for(valid_nested_data)
      end
    end
  end
end
