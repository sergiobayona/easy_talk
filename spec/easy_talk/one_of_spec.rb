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
        type: 'object',
        '$defs': {
          PhoneNumber: {
            type: 'object',
            properties: {
              phone_number: {
                type: 'string',
                format: 'phone'
              }
            }
          },
          EmailAddress: {
            type: 'object',
            properties: {
              email: {
                type: 'string',
                format: 'email'
              }
            }
          }
        },
        oneOf: [
          {
            '$ref': '#/$defs/PhoneNumber'
          },
          {
            '$ref': '#/$defs/EmailAddress'
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
        type: 'object',
        title: 'User',
        properties: {
          contactDetail: {
            oneOf: [
              {
                type: 'object',
                properties: {
                  phone_number: {
                    type: 'string',
                    format: 'phone'
                  }
                }
              },
              {
                type: 'object',
                properties: {
                  email: {
                    type: 'string',
                    format: 'email'
                  }
                }
              }
            ]
          }
        },
        required: ['contactDetail']
      }
    end

    it 'returns the schema with oneOf for the property' do
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
        type: 'object',
        title: 'User',
        properties: {
          contactDetail: {
            oneOf: [
              {
                type: 'string',
                format: 'email'
              },
              {
                type: 'string',
                format: 'phone'
              }
            ]
          }
        },
        required: ['contactDetail']
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

  context 'with primitive types in OneOf' do
    let(:model_class) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'PrimitiveTypesModel'
        end

        define_schema do
          property :string_or_number, T::OneOf[String, Float], optional: true
          property :string_or_integer, T::OneOf[String, Integer], optional: true
        end
      end
    end

    it 'correctly maps Float to "number" JSON Schema type' do
      json_schema = model_class.json_schema
      # The properties hash is accessed with string keys in the final schema
      string_or_number = json_schema["properties"]["string_or_number"]
      expect(string_or_number).to include_json(
        oneOf: [
          { type: 'string' },
          { type: 'number' }  # Float should map to 'number', not 'float'
        ]
      )
    end

    it 'correctly maps Integer to "integer" JSON Schema type' do
      json_schema = model_class.json_schema
      # The properties hash is accessed with string keys in the final schema
      string_or_integer = json_schema["properties"]["string_or_integer"]
      expect(string_or_integer).to include_json(
        oneOf: [
          { type: 'string' },
          { type: 'integer' }
        ]
      )
    end
  end
end
