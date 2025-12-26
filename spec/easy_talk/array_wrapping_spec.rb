# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Array wrapping' do
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

  let(:addresses) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'Addresses'
      end

      define_schema do
        property :addresses, T::Array[Address]
        property :details, T::Array[T::OneOf[PhoneNumber, EmailAddress]]
        property :detail_ref, T::OneOf[PhoneNumber, EmailAddress], ref: true
        property :details_ref, T::Array[T::OneOf[PhoneNumber, EmailAddress]], ref: true
      end
    end
  end

  it 'wraps an array in an object' do
    stub_const('Address', address)
    stub_const('PhoneNumber', phone_number)
    stub_const('EmailAddress', email_address)
    stub_const('Addresses', addresses)
    JSON.pretty_generate(Addresses.json_schema)
    expect(Addresses.json_schema).to eq({
                                          '$defs' => {
                                            'PhoneNumber' => {
                                              'type' => 'object',
                                              'properties' => {
                                                'phone_number' => {
                                                  'format' => 'phone',
                                                  'type' => 'string'
                                                }
                                              },
                                              'required' => ['phone_number'],
                                              'additionalProperties' => false
                                            },
                                            'EmailAddress' => {
                                              'type' => 'object',
                                              'properties' => {
                                                'email' => {
                                                  'format' => 'email',
                                                  'type' => 'string'
                                                }
                                              },
                                              'required' => ['email'],
                                              'additionalProperties' => false
                                            }
                                          },
                                          'type' => 'object',
                                          'properties' => {
                                            'addresses' => {
                                              'type' => 'array',
                                              'items' => {
                                                'type' => 'object',
                                                'properties' => {
                                                  'street' => {
                                                    'type' => 'string'
                                                  },
                                                  'city' => {
                                                    'type' => 'string'
                                                  },
                                                  'state' => {
                                                    'type' => 'string'
                                                  }, 'zip' => {
                                                    'type' => 'string',
                                                    'pattern' => '^[0-9]{5}(?:-[0-9]{4})?$'
                                                  }
                                                },
                                                'additionalProperties' => false,
                                                'required' => %w[street city state zip]
                                              }
                                            },
                                            'details' => {
                                              'type' => 'array',
                                              'items' => {
                                                'type' => 'object',
                                                'oneOf' => [
                                                  {
                                                    'type' => 'object',
                                                    'properties' => {
                                                      'phone_number' => {
                                                        'format' => 'phone',
                                                        'type' => 'string'
                                                      }
                                                    },
                                                    'required' => ['phone_number'],
                                                    'additionalProperties' => false
                                                  },
                                                  {
                                                    'type' => 'object',
                                                    'properties' => {
                                                      'email' => {
                                                        'format' => 'email',
                                                        'type' => 'string'
                                                      }
                                                    },
                                                    'required' => ['email'],
                                                    'additionalProperties' => false
                                                  }
                                                ]
                                              }
                                            },
                                            'details_ref' => {
                                              'type' => 'array',
                                              'items' => {
                                                'type' => 'object',
                                                'oneOf' => [
                                                  {
                                                    '$ref' => '#/$defs/PhoneNumber'
                                                  },
                                                  {
                                                    '$ref' => '#/$defs/EmailAddress'
                                                  }
                                                ]
                                              }
                                            },
                                            'detail_ref' => {
                                              'type' => 'object',
                                              'oneOf' => [
                                                {
                                                  '$ref' => '#/$defs/PhoneNumber'
                                                },
                                                {
                                                  '$ref' => '#/$defs/EmailAddress'
                                                }
                                              ]
                                            }
                                          },
                                          'additionalProperties' => false,
                                          'required' => %w[addresses details detail_ref details_ref]
                                        })
  end
end
