# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Vehicle Registration System example' do
  let(:vehicle_identification) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'VehicleIdentification'
      end

      define_schema do
        title 'Vehicle Identification'
        property :make, String
        property :model, String
        property :year, Integer, minimum: 1900, maximum: 2100
        property :vin, String
        additional_properties true
      end
    end
  end

  let(:owner_info) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'OwnerInfo'
      end

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
  end

  let(:registration_details) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'RegistrationDetails'
      end

      define_schema do
        title 'Registration Details'
        property :registration_number, String, pattern: '^[A-Z0-9]{7}$'
        property :registration_date, String, format: 'date'
        property :expiration_date, String, format: 'date'
      end
    end
  end

  let(:vehicle_registration) do
    Class.new do
      def self.name
        'VehicleRegistration'
      end

      include EasyTalk::Model
    end
  end

  let(:expected_schema) do
    {
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
    }
  end

  it 'returns a json schema for a payment object' do
    stub_const('VehicleIdentification', vehicle_identification)
    stub_const('OwnerInfo', owner_info)
    stub_const('RegistrationDetails', registration_details)

    vehicle_registration.define_schema do
      compose T::AllOf[VehicleIdentification, OwnerInfo, RegistrationDetails]
    end

    expect(vehicle_registration.json_schema).to include_json(expected_schema)
  end
end
