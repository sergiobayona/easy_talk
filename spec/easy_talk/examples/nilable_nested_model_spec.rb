# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'combining nested models with nilable' do
  let(:address) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'Address'
      end
    end
  end
  let(:expected_json_schema) do
    {
      "title" => "Company",
      "type" => "object",
      "properties" => {
        "name" => { "type" => "string" },
        "address" => {
          "title" => "Address",
          "type" => %w[object null],
          "properties" => {
            "street" => { "type" => "string" },
            "city" => { "type" => "string" },
            "state" => { "type" => "string" }
          },
          "additionalProperties" => false,
          "required" => %w[street city state]
        }
      },
      "additionalProperties" => false,
      "required" => %w[name address]
    }
  end

  let(:company) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'Company'
      end
    end
  end

  before do
    stub_const('Address', address)
    stub_const('Company', company)

    Address.define_schema do
      title 'Address'
      property :street, String
      property :city, String
      property :state, String
    end

    Company.define_schema do
      title 'Company'
      property :name, String
      property :address, T.nilable(Address)
    end
  end

  it 'builds a JSON schema' do
    expect(Company.json_schema).to eq(expected_json_schema)
  end

  it "allows passing nil as a value for the nested model" do
    company = Company.new(name: 'Acme', address: nil)

    expect(company.address).to be_nil
    expect(company).to be_valid
  end

  it "allows passing a hash as a value for the nested model" do
    company = Company.new(name: 'Acme', address: { street: '123 Main St', city: 'Anytown', state: 'NY' })

    expect(company).to be_valid
    expect(company.address).to be_a(Address)
    expect(company.address).to be_valid
    expect(company.address.street).to eq('123 Main St')
    expect(company.address.city).to eq('Anytown')
    expect(company.address.state).to eq('NY')
  end
end
