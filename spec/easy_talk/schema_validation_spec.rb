# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'validing json' do
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
        property :email, :object do
          property :address, String
          property :verified, String
        end
      end
    end
  end

  describe 'top level properties' do
    it 'validates the nil name' do
      jim = user.new(name: nil, age: 30, height: 5.9, email: { address: 'jim@test.com', verified: 'true' })
      expect(jim.valid?).to be false
      expect(jim.errors.size).to eq(1)
      expect(jim.errors[:name]).to eq(['is not a valid string'])
    end

    it 'passes validation on empty name' do
      jim = user.new(name: '', age: 30, height: 5.9, email: { address: 'jim@test.com', verified: 'true' })
      expect(jim.valid?).to be true
    end

    it 'validates age attribute is not present' do
      jim = user.new(name: 'Jim', height: 5.9, email: { address: 'jim@test.com', verified: 'true' })
      expect(jim.valid?).to be false
      expect(jim.errors.size).to eq(1)
      expect(jim.errors[:age]).to eq(["can't be blank"])
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

  describe 'properties on nested objects' do
    it 'validates nested properties' do
      jim = user.new(name: 'Jim', age: 30, height: 5.9, email: { address: 'test@test.com' })
      jim.valid?
      expect(jim.errors['email.verified']).to eq(["can't be blank"])
    end
  end

  it 'errors on invalid age' do
    jim = user.new(name: 'Jim', age: 'thirty', height: 4.5, email: { address: 'test@jim.com', verified: 'true' })
    expect(jim.valid?).to be false
    expect(jim.errors.size).to eq(1)
    expect(jim.errors[:age]).to eq(['is not a valid integer'])
  end
end
