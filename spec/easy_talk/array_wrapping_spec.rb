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
        property :zip, String, pattern: '^[0-9]{5}(?:-[0-9]{4})?$'
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
      end
    end
  end

  it 'wraps an array in an object' do
    stub_const('Address', address)
    stub_const('Addresses', addresses)
    expect(Addresses.json_schema).to eq({ 'type' => 'object',
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
                                            }
                                          },
                                          'additionalProperties' => false,
                                          'required' => ['addresses'] })
  end
end
