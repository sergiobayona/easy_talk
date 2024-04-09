# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Vehicle Registration System example' do
  class VehicleIdentification
    include EasyTalk::Model

    define_schema do
      title 'Vehicle Identification'
      property :make, String
      property :model, String
      property :year, Integer, minimum: 1900, maximum: 2100
      property :vin, String
      additional_properties true
    end
  end

  class OwnerInfo
    include EasyTalk::Model

    define_schema do
      title 'Owner Information'
      property :first_name, String
      property :last_name, String
      property :address, String
      property :city, String
      property :state, String
      property :zip, String
      property :contact_number, String, pattern: '^[0-9]{10}$'
    end
  end

  class RegistrationDetails
    include EasyTalk::Model

    define_schema do
      title 'Registration Details'
      property :registration_number, String, pattern: '^[A-Z0-9]{7}$'
      property :registration_date, String, format: 'date'
      property :expiration_date, String, format: 'date'
    end
  end

  class VehicleRegistration
    include EasyTalk::Model

    define_schema do
      compose T::AllOf[VehicleIdentification, OwnerInfo, RegistrationDetails]
    end
  end

  context 'json schema' do
    it 'returns a json schema for a payment object' do
      expect(VehicleRegistration.json_schema).to include_json({
                                                                "type": 'object',
                                                                "$defs": {
                                                                  "VehicleIdentification": {
                                                                    "type": 'object',
                                                                    "title": 'Vehicle Identification',
                                                                    "properties": {
                                                                      "make": {
                                                                        "type": 'string'
                                                                      },
                                                                      "model": {
                                                                        "type": 'string'
                                                                      },
                                                                      "year": {
                                                                        "type": 'integer',
                                                                        "minimum": 1900,
                                                                        "maximum": 2100
                                                                      },
                                                                      "vin": {
                                                                        "type": 'string'
                                                                      }
                                                                    },
                                                                    "additionalProperties": true,
                                                                    "required": %w[
                                                                      make
                                                                      model
                                                                      year
                                                                      vin
                                                                    ]
                                                                  },
                                                                  "OwnerInfo": {
                                                                    "type": 'object',
                                                                    "title": 'Owner Information',
                                                                    "properties": {
                                                                      "first_name": {
                                                                        "type": 'string'
                                                                      },
                                                                      "last_name": {
                                                                        "type": 'string'
                                                                      },
                                                                      "address": {
                                                                        "type": 'string'
                                                                      },
                                                                      "city": {
                                                                        "type": 'string'
                                                                      },
                                                                      "state": {
                                                                        "type": 'string'
                                                                      },
                                                                      "zip": {
                                                                        "type": 'string'
                                                                      },
                                                                      "contact_number": {
                                                                        "type": 'string',
                                                                        "pattern": '^[0-9]{10}$'
                                                                      }
                                                                    },
                                                                    "required": %w[
                                                                      first_name
                                                                      last_name
                                                                      address
                                                                      city
                                                                      state
                                                                      zip
                                                                      contact_number
                                                                    ]
                                                                  },
                                                                  "RegistrationDetails": {
                                                                    "type": 'object',
                                                                    "title": 'Registration Details',
                                                                    "properties": {
                                                                      "registration_number": {
                                                                        "type": 'string',
                                                                        "pattern": '^[A-Z0-9]{7}$'
                                                                      },
                                                                      "registration_date": {
                                                                        "type": 'string',
                                                                        "format": 'date'
                                                                      },
                                                                      "expiration_date": {
                                                                        "type": 'string',
                                                                        "format": 'date'
                                                                      }
                                                                    },
                                                                    "required": %w[
                                                                      registration_number
                                                                      registration_date
                                                                      expiration_date
                                                                    ]
                                                                  }
                                                                },
                                                                "allOf": [
                                                                  {
                                                                    "$ref": '#/$defs/VehicleIdentification'
                                                                  },
                                                                  {
                                                                    "$ref": '#/$defs/OwnerInfo'
                                                                  },
                                                                  {
                                                                    "$ref": '#/$defs/RegistrationDetails'
                                                                  }
                                                                ]
                                                              })
    end
  end
end
