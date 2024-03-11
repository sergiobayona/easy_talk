# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Product catalog example' do
  class BaseProduct
    include EasyTalk::Model

    define_schema do
      property :productId, String, format: 'uuid'
      property :name, String
      property :description, String
      property :price, Float
      property :currency, String, enum: %w[USD EUR GBP]
    end
  end

  class ClothingProduct < BaseProduct
    define_schema do
      title 'Clothing Product'
      property :size, String, enum: %w[XS S M L XL XXL]
      property :color, String
      property :material, String
    end
  end

  context 'json schema' do
    it 'returns a json schema for a payment object' do
      expect(ClothingProduct.json_schema).to include_json({
                                                            "type": 'object',
                                                            "title": 'Clothing Product',
                                                            "properties": {
                                                              "size": {
                                                                "type": 'string',
                                                                "enum": %w[
                                                                  XS
                                                                  S
                                                                  M
                                                                  L
                                                                  XL
                                                                  XXL
                                                                ]
                                                              },
                                                              "color": {
                                                                "type": 'string'
                                                              },
                                                              "material": {
                                                                "type": 'string'
                                                              }
                                                            },
                                                            "required": %w[
                                                              size
                                                              color
                                                              material
                                                            ],
                                                            "$defs": {
                                                              "BaseProduct": {
                                                                "productId": {
                                                                  "type": 'string',
                                                                  "format": 'uuid'
                                                                },
                                                                "name": {
                                                                  "type": 'string'
                                                                },
                                                                "description": {
                                                                  "type": 'string'
                                                                },
                                                                "price": {
                                                                  "type": 'number'
                                                                },
                                                                "currency": {
                                                                  "type": 'string',
                                                                  "enum": %w[
                                                                    USD
                                                                    EUR
                                                                    GBP
                                                                  ]
                                                                }
                                                              }
                                                            },
                                                            "allOf": [
                                                              {
                                                                "$ref": '#/$defs/BaseProduct'
                                                              }
                                                            ]
                                                          })
    end
  end
end
