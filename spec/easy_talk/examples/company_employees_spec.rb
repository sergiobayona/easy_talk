# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'json for user model' do
  let(:company) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'Company'
      end
    end
  end

  let(:address) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'Address'
      end

      define_schema do
        property :street, String
        property :city, String
        property :state, String
        property :zip, String, pattern: '\A[0-9]{5}(?:-[0-9]{4})?\z'
      end
    end
  end

  let(:employee) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'Employee'
      end
    end
  end

  let(:expected_json_schema) do
    {
      "type": 'object',
      "title": 'Company',
      "properties": {
        "name": {
          "type": 'string'
        },
        "employees": {
          "type": 'array',
          "title": 'Company Employees',
          "description": 'A list of company employees',
          "items": {
            "type": 'object',
            "title": 'Employee',
            "description": 'Company employee',
            "properties": {
              "name": {
                "type": 'string',
                "title": 'Full Name'
              },
              "gender": {
                "type": 'string',
                "enum": %w[
                  male
                  female
                  other
                ]
              },
              "department": {
                "type": %w[string null]
              },
              "hire_date": {
                "type": 'string',
                "format": 'date'
              },
              "active": {
                "type": 'boolean',
                "default": true
              },
              "addresses": {
                "anyOf": [
                  {
                    "type": 'array',
                    "items": {
                      "type": 'object',
                      "properties": {
                        "street": {
                          "type": 'string'
                        },
                        "city": {
                          "type": 'string'
                        },
                        "state": {
                          "type": 'string'
                        },
                        "zip": {
                          "type": 'string',
                          "pattern": '\A[0-9]{5}(?:-[0-9]{4})?\z'
                        }
                      },
                      "required": %w[
                        street
                        city
                        state
                        zip
                      ]
                    }
                  },
                  {
                    "type": 'null'
                  }
                ]
              }
            },
            "required": %w[
              name
              gender
              department
              hire_date
              active
            ]
          }
        }
      },
      "required": %w[
        name
        employees
      ]
    }
  end

  it 'enhances the schema using the provided block' do
    stub_const('Address', address)
    stub_const('Employee', employee)
    stub_const('Company', company)

    Employee.define_schema do
      title 'Employee'
      description 'Company employee'
      property :name, String, title: 'Full Name'
      property :gender, String, enum: %w[male female other]
      property :department, T.nilable(String)
      property :hire_date, Date
      property :active, T::Boolean, default: true
      property :addresses, T.nilable(T::Array[Address])
    end

    Company.define_schema do
      title 'Company'
      property :name, String
      property :employees, T::Array[Employee], title: 'Company Employees', description: 'A list of company employees'
    end

    expect(company.json_schema).to include_json(expected_json_schema)
  end
end
