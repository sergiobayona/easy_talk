# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Payment object example' do
  class CreditCard
    include EasyTalk::Model

    define_schema do
      property 'CardNumber', String
      property 'CardType', String, enum: %w[Visa MasterCard AmericanExpress]
      property 'CardExpMonth', Integer, minimum: 1, maximum: 12
      property 'CardExpYear', Integer, minimum: Date.today.year, maximum: Date.today.year + 10
      property 'CardCVV', String, pattern: '^[0-9]{3,4}$'
      additional_properties false
    end
  end

  class Paypal
    include EasyTalk::Model

    define_schema do
      property 'PaypalEmail', String, format: 'email'
      property 'PaypalPasswordEncrypted', String
      additional_properties false
    end
  end

  class BankTransfer
    include EasyTalk::Model

    define_schema do
      property 'BankName', String
      property 'AccountNumber', String
      property 'RoutingNumber', String
      property 'AccountType', String, enum: %w[Checking Savings]
      additional_properties false
    end
  end

  class Payment
    include EasyTalk::Model

    define_schema do
      title 'Payment'
      description 'Payment info'
      property 'PaymentMethod', String, enum: %w[CreditCard Paypal BankTransfer]
      property 'Details', T.any(CreditCard, Paypal, BankTransfer)
    end
  end

  context 'json schema' do
    it 'returns a json schema for a payment object' do
      expect(Payment.json_schema).to include_json({
                                                    "title": 'Payment',
                                                    "description": 'Payment info',
                                                    "type": 'object',
                                                    "properties": {
                                                      "PaymentMethod": {
                                                        "type": 'string',
                                                        "enum": %w[
                                                          CreditCard
                                                          Paypal
                                                          BankTransfer
                                                        ]
                                                      },
                                                      "Details": {
                                                        "anyOf": [
                                                          {
                                                            "type": 'object',
                                                            "properties": {
                                                              "CardNumber": {
                                                                "type": 'string'
                                                              },
                                                              "CardType": {
                                                                "type": 'string',
                                                                "enum": %w[
                                                                  Visa
                                                                  MasterCard
                                                                  AmericanExpress
                                                                ]
                                                              },
                                                              "CardExpMonth": {
                                                                "type": 'integer',
                                                                "minimum": 1,
                                                                "maximum": 12
                                                              },
                                                              "CardExpYear": {
                                                                "type": 'integer',
                                                                "minimum": 2024,
                                                                "maximum": 2034
                                                              },
                                                              "CardCVV": {
                                                                "type": 'string',
                                                                "pattern": '^[0-9]{3,4}$'
                                                              }
                                                            },
                                                            "additional_properties": false,
                                                            "required": %w[
                                                              CardNumber
                                                              CardType
                                                              CardExpMonth
                                                              CardExpYear
                                                              CardCVV
                                                            ]
                                                          },
                                                          {
                                                            "type": 'object',
                                                            "properties": {
                                                              "PaypalEmail": {
                                                                "type": 'string',
                                                                "format": 'email'
                                                              },
                                                              "PaypalPasswordEncrypted": {
                                                                "type": 'string'
                                                              }
                                                            },
                                                            "additional_properties": false,
                                                            "required": %w[
                                                              PaypalEmail
                                                              PaypalPasswordEncrypted
                                                            ]
                                                          },
                                                          {
                                                            "type": 'object',
                                                            "properties": {
                                                              "BankName": {
                                                                "type": 'string'
                                                              },
                                                              "AccountNumber": {
                                                                "type": 'string'
                                                              },
                                                              "RoutingNumber": {
                                                                "type": 'string'
                                                              },
                                                              "AccountType": {
                                                                "type": 'string',
                                                                "enum": %w[
                                                                  Checking
                                                                  Savings
                                                                ]
                                                              }
                                                            },
                                                            "additional_properties": false,
                                                            "required": %w[
                                                              BankName
                                                              AccountNumber
                                                              RoutingNumber
                                                              AccountType
                                                            ]
                                                          }
                                                        ]
                                                      }
                                                    },
                                                    "required": %w[
                                                      PaymentMethod
                                                      Details
                                                    ]
                                                  })
    end
  end
end
