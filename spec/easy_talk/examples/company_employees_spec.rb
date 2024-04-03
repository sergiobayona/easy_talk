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

  describe '.json_schema' do
    class Address
      include EasyTalk::Model

      define_schema do
        property :street, String
        property :city, String
        property :state, String
        property :zip, String, pattern: '^[0-9]{5}(?:-[0-9]{4})?$'
      end
    end

    class Employee
      include EasyTalk::Model
      define_schema do
        title 'Employee'
        description 'Company employee'
        property :name, String, title: 'Full Name'
        property :gender, String, enum: %w[male female other]
        property :department, String
        property :hire_date, Date
        property :active, T::Boolean, default: true
        property :addresses, T.nilable(T::Array[Address])
      end
    end

    it 'enhances the schema using the provided block' do
      company.define_schema do
        title 'Company'
        property :name, String
        property :employees, T::Array[Employee]
      end

      puts company.json_schema
      expect(company.json_schema).to include_json({
                                                    "type": 'object',
                                                    "title": 'Company',
                                                    "properties": {
                                                      "name": {
                                                        "type": 'string'
                                                      },
                                                      "employees": {
                                                        "type": 'array',
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
                                                              "type": 'string'
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
                                                                        "pattern": '^[0-9]{5}(?:-[0-9]{4})?$'
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
                                                  })
    end
  end
end
