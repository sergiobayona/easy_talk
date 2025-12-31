# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'validating json' do
  before do
    # Define Email class for use in testing
    class Email
      include EasyTalk::Model

      define_schema do
        property :address, String
        property :verified, String
      end
    end
  end

  after do
    # Clean up the Email class after tests
    Object.send(:remove_const, :Email) if Object.const_defined?(:Email)
  end

  let(:user) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'User'
      end

      define_schema do
        property :name, String
        property :age, Integer
        property :height, Float
        property :email, Email
      end
    end
  end

  describe 'top level properties' do
    it 'validates the nil name' do
      jim = user.new(name: nil, age: 30, height: 5.9, email: { address: 'jim@test.com', verified: 'true' })
      expect(jim.valid?).to be false
      expect(jim.errors.size).to eq(1)
      expect(jim.errors[:name]).to eq(["can't be blank"])
    end

    # NOTE: Per JSON Schema spec, empty strings are valid. However, we are using ActiveModel validations
    # and It do not allow empty strings.
    it 'fails validation on empty name' do
      jim = user.new(name: '', age: 30, height: 5.9, email: { address: 'jim@test.com', verified: 'true' })
      expect(jim.valid?).to be false
      expect(jim.errors.size).to eq(1)
      expect(jim.errors[:name]).to eq(["can't be blank"])
    end

    it 'validates age attribute is not present' do
      jim = user.new(name: 'Jim', height: 5.9, email: { address: 'jim@test.com', verified: 'true' })
      expect(jim.valid?).to be false
      expect(jim.errors.size).to eq(2)
      expect(jim.errors[:age]).to eq(["can't be blank", 'is not a number'])
    end

    it 'validates email attribute is not present' do
      jim = user.new(name: 'Jim', age: 30, height: 5.9)
      expect(jim.valid?).to be false
      expect(jim.errors.size).to eq(1)
      expect(jim.errors[:email]).to eq(["can't be blank"])
    end

    it 'validates an empty email hash' do
      jim = user.new(name: 'Jim', age: 30, height: 5.9, email: {})
      expect(jim.valid?).to be false
      expect(jim.errors.size).to eq(1)
      expect(jim.errors['email']).to eq(["can't be blank"])
    end
  end

  it 'validates nested properties' do
    jim = user.new(name: 'Jim', age: 30, height: 5.9, email: { address: 'test@test.com' })
    jim.valid?
    expect(jim.errors['email.verified']).to eq(["can't be blank"])
  end

  it 'errors on invalid age' do
    jim = user.new(name: 'Jim', age: 'thirty', height: 4.5, email: { address: 'test@jim.com', verified: 'true' })
    expect(jim.valid?).to be false
    expect(jim.errors.size).to eq(1)
    expect(jim.errors[:age]).to eq(['is not a number'])
  end

  # JSON Schema Compliance Gap: Type Coercion
  # Per JSON Schema spec, a string "30" should NOT be valid for type: integer.
  # Currently, EasyTalk uses ActiveModel's numericality validation which coerces
  # strings to numbers, allowing "30" to pass validation for Integer properties.
  # This test documents the current behavior - when strict type checking is
  # implemented, the pending block should be activated.
  describe 'type coercion (JSON Schema compliance gap)' do
    it 'currently allows string "30" for Integer property (coercion behavior)' do
      jim = user.new(name: 'Jim', age: '30', height: 5.9, email: { address: 'test@jim.com', verified: 'true' })
      # Current behavior: string "30" passes because numericality validator coerces it
      expect(jim.valid?).to be true
    end

    pending 'should reject string "30" for Integer property (strict JSON Schema compliance)' do
      jim = user.new(name: 'Jim', age: '30', height: 5.9, email: { address: 'test@jim.com', verified: 'true' })
      # Expected behavior per JSON Schema: string is not an integer, even if numeric
      expect(jim.valid?).to be false
      expect(jim.errors[:age]).to include('must be an integer')
    end
  end
end
