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

  let(:expected_defs) do
    {
      'PhoneNumber' => {
        'type' => 'object',
        'properties' => {
          'phone_number' => { 'format' => 'phone', 'type' => 'string' }
        },
        'required' => ['phone_number'],
        'additionalProperties' => false
      },
      'EmailAddress' => {
        'type' => 'object',
        'properties' => {
          'email' => { 'format' => 'email', 'type' => 'string' }
        },
        'required' => ['email'],
        'additionalProperties' => false
      }
    }
  end

  before do
    stub_const('Address', address)
    stub_const('PhoneNumber', phone_number)
    stub_const('EmailAddress', email_address)
    stub_const('Addresses', addresses)
  end

  it 'generates $defs for referenced models' do
    expect(Addresses.json_schema['$defs']).to eq(expected_defs)
  end

  it 'wraps array of models with inline schema' do
    addresses_prop = Addresses.json_schema['properties']['addresses']

    expect(addresses_prop['type']).to eq('array')
    expect(addresses_prop['items']['type']).to eq('object')
    expect(addresses_prop['items']['properties']).to include('street', 'city', 'state', 'zip')
  end

  it 'wraps array with oneOf composition inline' do
    details_prop = Addresses.json_schema['properties']['details']

    expect(details_prop['type']).to eq('array')
    expect(details_prop['items']['oneOf']).to be_an(Array)
    expect(details_prop['items']['oneOf'].length).to eq(2)
  end

  it 'wraps array with oneOf composition using $ref' do
    details_ref_prop = Addresses.json_schema['properties']['details_ref']

    expect(details_ref_prop['type']).to eq('array')
    expect(details_ref_prop['items']['oneOf']).to contain_exactly(
      { '$ref' => '#/$defs/PhoneNumber' },
      { '$ref' => '#/$defs/EmailAddress' }
    )
  end

  it 'wraps single oneOf composition using $ref' do
    detail_ref_prop = Addresses.json_schema['properties']['detail_ref']

    expect(detail_ref_prop['type']).to eq('object')
    expect(detail_ref_prop['oneOf']).to contain_exactly(
      { '$ref' => '#/$defs/PhoneNumber' },
      { '$ref' => '#/$defs/EmailAddress' }
    )
  end

  it 'includes all properties in required array' do
    expect(Addresses.json_schema['required']).to contain_exactly(
      'addresses', 'details', 'detail_ref', 'details_ref'
    )
  end
end
