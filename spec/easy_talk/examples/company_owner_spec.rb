# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'json for user model' do
  let(:company) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'Company'
      end
    end
  end

  let(:owner) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'Owner'
      end

      define_schema do
        property :first_name, String
        property :last_name, String
        property :dob, String
      end
    end
  end

  it 'enhances the schema using the provided block' do
    stub_const('Owner', owner)
    stub_const('Company', company)

    Company.define_schema do
      title 'Company'
      property :name, String
      property :owner, Owner, title: 'Owner', description: 'The company owner'
    end

    expected_schema = {
      'type' => 'object',
      'title' => 'Company',
      'properties' => {
        'name' => {
          'type' => 'string'
        },
        'owner' => {
          'type' => 'object',
          'title' => 'Owner',
          'description' => 'The company owner',
          'properties' => {
            'first_name' => {
              'type' => 'string'
            },
            'last_name' => {
              'type' => 'string'
            },
            'dob' => {
              'type' => 'string'
            }
          },
          'required' => %w[first_name last_name dob]
        }
      },
      'required' => %w[name owner]
    }

    expect(company.json_schema).to include_json(expected_schema)
  end
end
