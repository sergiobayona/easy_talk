# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::Model do
  let(:user) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'User'
      end
    end
  end

  it "returns nil because it hasn't been defined" do
    expect(user.schema_definition).to eq({})
  end

  it "returns the function name 'User'" do
    expect(user.function_name).to eq('User')
  end

  it 'does not inherit schema' do
    expect(user.inherits_schema?).to eq(false)
  end

  it 'returns a ref template' do
    expect(user.ref_template).to eq('#/$defs/User')
  end

  describe '.schema_definition' do
    it 'enhances the schema using the provided block' do
      user.define_schema do
        title 'User'
      end

      expect(user.schema_definition).to be_a(EasyTalk::SchemaDefinition)
    end
  end

  describe 'validating a JSON object' do
    it 'validates the JSON object against the schema' do
      user.define_schema do
        title 'User'
        property :name, String
        property :age, Integer
      end

      expect(user.validate_json({ name: 'John', age: 21 })).to eq(true)
    end

    it 'fails validation of the JSON object against the schema' do
      user.define_schema do
        title 'User'
        property :name, String
        property :age, Integer
      end

      expect(user.validate_json({ name: 'John', age: '21' })).to eq(false)
    end
  end
end
