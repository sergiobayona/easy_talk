# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::Types::Composer::OneOf do
  let(:phone_number) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'PhoneNumber'
      end

      define_schema do
        property :phone_number, String, format: 'phone'
      end
    end
  end

  let(:email_address) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'EmailAddress'
      end

      define_schema do
        property :email, String, format: 'email'
      end
    end
  end

  let(:user) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'User'
      end
    end
  end

  context 'with OneOf as a root node' do
    let(:expected_json_schema) do
      {
        "type": 'object',
        "$defs": {
          "PhoneNumber": {
            "type": 'object',
            "properties": {
              "phone_number": {
                "type": 'string',
                "format": 'phone'
              }
            }
          },
          "EmailAddress": {
            "type": 'object',
            "properties": {
              "email": {
                "type": 'string',
                "format": 'email'
              }
            }
          }
        },
        "oneOf": [
          {
            "$ref": '#/$defs/PhoneNumber'
          },
          {
            "$ref": '#/$defs/EmailAddress'
          }
        ]
      }
    end

    it 'returns the object with the definitions and references' do
      stub_const('PhoneNumber', phone_number)
      stub_const('EmailAddress', email_address)

      user.define_schema do
        property :name, String
        compose T::OneOf[PhoneNumber, EmailAddress]
      end
      expect(user.json_schema).to include_json(expected_json_schema)
    end
  end

  context 'with OneOf within a model property' do
    let(:expected_json_schema) do
      {
        "type": 'object',
        "title": 'User',
        "properties": {
          "contactDetail": {
            "oneOf": [
              {
                "type": 'object',
                "properties": {
                  "phone_number": {
                    "type": 'string',
                    "format": 'phone'
                  }
                }
              },
              {
                "type": 'object',
                "properties": {
                  "email": {
                    "type": 'string',
                    "format": 'email'
                  }
                }
              }
            ]
          }
        },
        "required": ['contactDetail']
      }
    end

    it 'not supported yet' do
      stub_const('PhoneNumber', phone_number)
      stub_const('EmailAddress', email_address)

      user.define_schema do
        title 'User'
        property :contactDetail, T::OneOf[PhoneNumber, EmailAddress]
      end

      expect(user.json_schema).to include_json(expected_json_schema)
    end
  end

  context 'with the `field` keyword' do
    let(:expected_schema) do
      {
        "type": 'object',
        "title": 'User',
        "properties": {
          "contactDetail": {
            "oneOf": [
              {
                "type": 'string',
                "format": 'email'
              },
              {
                "type": 'string',
                "format": 'phone'
              }
            ]
          }
        },
        "required": ['contactDetail']
      }
    end

    pending 'not supported yet' do
      user.define_schema do
        title 'User'
        field :phone_number, String, format: 'phone'
        field :email, String, format: 'email'
        property :contactDetail, T::OneOf[:phone_number, :email]
      end

      expect(user.json_schema).to include_json(expected_schema)
    end
  end
end
