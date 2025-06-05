# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Contact info. Example using compositional keyword: oneOf' do
  let(:phone_contact) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'PhoneContact'
      end

      define_schema do
        property :phone_number, String, pattern: '\A(?:\+?1[-. ]?)?\(?([0-9]{3})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})\z'
      end
    end
  end

  let(:email_contact) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'EmailContact'
      end

      define_schema do
        property :email, String, format: 'email'
      end
    end
  end

  let(:contact) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'Contact'
      end
    end
  end

  let(:expected_json_schema) do
    {
      type: 'object',
      title: 'Contact Info',
      properties: {
        contact: {
          type: 'object',
          oneOf: [
            {
              type: 'object',
              properties: {
                phone_number: {
                  type: 'string',
                  pattern: '\A(?:\+?1[-. ]?)?\(?([0-9]{3})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})\z'
                }
              },
              required: [
                'phone_number'
              ]
            },
            {
              type: 'object',
              properties: {
                email: {
                  type: 'string',
                  format: 'email'
                }
              },
              required: [
                'email'
              ]
            }
          ]
        }
      },
      required: [
        'contact'
      ]
    }
  end

  it 'returns a json schema for the book class' do
    stub_const('PhoneContact', phone_contact)
    stub_const('EmailContact', email_contact)
    stub_const('Contact', contact)

    Contact.define_schema do
      title 'Contact Info'
      property :contact, T::OneOf[PhoneContact, EmailContact]
    end
    expect(Contact.json_schema).to include_json(expected_json_schema)
  end
end
