# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Payment object example' do
  let(:credit_card) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'CreditCard'
      end

      define_schema do
        property :CardNumber, String
        property :CardType, String, enum: %w[Visa MasterCard AmericanExpress]
        property :CardExpMonth, Integer, minimum: 1, maximum: 12
        property :CardExpYear, Integer, minimum: Date.today.year, maximum: Date.today.year + 10
        property :CardCVV, String, pattern: '^[0-9]{3,4}$'
        additional_properties false
      end
    end
  end

  let(:paypal) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'Paypal'
      end

      define_schema do
        property :PaypalEmail, String, format: 'email'
        property :PaypalPasswordEncrypted, String
        additional_properties false
      end
    end
  end

  let(:bank_transfer) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'BankTransfer'
      end

      define_schema do
        property :BankName, String
        property :AccountNumber, String
        property :RoutingNumber, String
        property :AccountType, String, enum: %w[Checking Savings]
        additional_properties false
      end
    end
  end

  let(:payment) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'Payment'
      end
    end
  end

  let(:expected_json_schema) do
    {
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
              "additionalProperties": false,
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
              "additionalProperties": false,
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
              "additionalProperties": false,
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
    }
  end

  it 'returns a json schema for a payment object' do
    stub_const('CreditCard', credit_card)
    stub_const('Paypal', paypal)
    stub_const('BankTransfer', bank_transfer)
    stub_const('Payment', payment)

    Payment.define_schema do
      title 'Payment'
      description 'Payment info'
      property :PaymentMethod, String, enum: %w[CreditCard Paypal BankTransfer]
      property :Details, T::AnyOf[CreditCard, Paypal, BankTransfer]
    end
    expect(Payment.json_schema).to include_json(expected_json_schema)
  end
end
