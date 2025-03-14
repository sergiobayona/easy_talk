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
end
