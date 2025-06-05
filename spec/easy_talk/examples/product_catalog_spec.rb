# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Product catalog example' do
  let(:base_product) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'BaseProduct'
      end

      define_schema do
        property :productId, String, format: 'uuid'
        property :name, String
        property :description, String
        property :price, Float
        property :currency, String, enum: %w[USD EUR GBP]
      end
    end
  end

  let(:clothing_product) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'ClothingProduct'
      end
    end
  end

  let(:expected_json_schema) do
    {
      type: 'object',
      title: 'Clothing Product',
      properties: {
        size: {
          type: 'string',
          enum: %w[
            XS
            S
            M
            L
            XL
            XXL
          ]
        },
        color: {
          type: 'string'
        },
        material: {
          type: 'string'
        }
      },
      required: %w[
        size
        color
        material
      ],
      '$defs': {
        BaseProduct: {
          type: 'object',
          properties: {
            productId: {
              type: 'string',
              format: 'uuid'
            },
            name: {
              type: 'string'
            },
            description: {
              type: 'string'
            },
            price: {
              type: 'number'
            },
            currency: {
              type: 'string',
              enum: %w[
                USD
                EUR
                GBP
              ]
            }
          },
          required: %w[
            productId
            name
            description
            price
            currency
          ]
        }
      },
      allOf: [
        {
          '$ref': '#/$defs/BaseProduct'
        }
      ]
    }
  end

  it 'returns a json schema for a payment object' do
    stub_const('BaseProduct', base_product)
    stub_const('ClothingProduct', clothing_product)

    ClothingProduct.define_schema do
      title 'Clothing Product'
      compose T::AllOf[BaseProduct]
      property :size, String, enum: %w[XS S M L XL XXL]
      property :color, String
      property :material, String
    end

    expect(ClothingProduct.json_schema).to include_json(expected_json_schema)
  end
end
