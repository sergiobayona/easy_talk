# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'validing json' do
  before do
    # Define Email class for use in testing
    class Email
      include EasyTalk::Model

      define_schema do
        property :address, String
        property :verified, T::Boolean
      end

      def [](key)
        send(key)
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

      validate do |person|
        MyValidator.new(person).validate
      end

      class MyValidator
        def initialize(person)
          @person = person
        end

        def validate
          @person.errors.add(:email, 'must end with @test.com') unless @person.email.address.ends_with?('@test.com')
        end
      end

      def self.name
        'User'
      end

      define_schema do
        property :name, String
        property :age, Integer, minimum: 21
        property :height, Float, minimum: 0
        property :email, Email
      end
    end
  end

  describe 'validating properties without ActiveModel validations' do
    before do
      EasyTalk.configuration.auto_validations = false
    end

    it 'does not validate the nil name' do
      email = Email.new(address: 'jim@test.com', verified: false)
      jim = user.new(name: nil, age: 30, height: 5.9, email: email)
      expect(jim.valid?).to be true
    end

    it 'does not validate the empty name' do
      email = Email.new(address: 'jim@test.com', verified: false)
      jim = user.new(name: '', age: 30, height: 5.9, email: email)
      expect(jim.valid?).to be true
    end

    it 'does not validate the property that is not present' do
      email = Email.new(address: 'jim@test.com', verified: false)
      jim = user.new(age: 30, height: 5.9, email: email)
      expect(jim.valid?).to be true
    end
  end

  it 'is valid' do
    email = Email.new(address: 'jim@test.com', verified: false)
    jim = user.new(name: 'Jim', age: 30, height: 5.9, email: email)
    is_valid = jim.valid?
    binding.pry
    # Print validation errors if the object is invalid to help debugging
    puts "\nValidation Errors: #{jim.errors.full_messages.join(', ')}\n" unless is_valid
    expect(is_valid).to be true
    # The expectation below is redundant if is_valid is true, but kept for clarity
    expect(jim.errors.size).to eq(0)
  end

  it 'errors on invalid age' do
    email = Email.new(address: 'jim@test.com', verified: false)
    jim = user.new(name: 'Jim', age: 18, height: 5.9, email: email)
    expect(jim.valid?).to be false
    expect(jim.errors.size).to eq(1)
    expect(jim.errors[:age]).to eq(['must be greater than or equal to 21'])
  end

  it 'errors on invalid email' do
    email = Email.new(address: 'jim@gmail.com', verified: false)
    jim = user.new(name: 'Jim', age: 30, height: 5.9, email: email)
    expect(jim.valid?).to be false
    expect(jim.errors.size).to eq(1)
    expect(jim.errors[:email]).to eq(['must end with @test.com'])
  end

  it 'errors on missing height' do
    email = Email.new(address: 'jim@gmailcom', verified: false)
    jim = user.new(name: 'Jim', age: 30, email: email)
    expect(jim.valid?).to be false
    expect(jim.errors[:height]).to eq(["can't be blank", 'is not a number'])
  end

  it 'errors on invalid height' do
    email = Email.new(address: 'jim@gmailcom', verified: false)
    jim = user.new(name: 'Jim', age: 30, height: -5.9, email: email)
    expect(jim.valid?).to be false
    expect(jim.errors[:height]).to eq(['must be greater than or equal to 0'])
  end

  it 'responds to #invalid?' do
    email = Email.new(address: 'jim@test.com', verified: false)
    jim = user.new(name: 'Jim', age: 18, height: 5.9, email: email)
    expect(jim.invalid?).to be true
  end

  it 'responds to #errors' do
    email = Email.new(address: 'jim@test.com', verified: false)
    jim = user.new(name: 'Jim', age: 18, height: 5.9, email: email)
    jim.valid?
    expect(jim.errors).to be_a(ActiveModel::Errors)
  end

  it 'responds to #errors.messages' do
    email = Email.new(address: 'jim@test.com', verified: false)
    jim = user.new(name: 'Jim', age: 18, height: 5.9, email: email)
    jim.valid?
    expect(jim.errors.messages).to eq(age: ['must be greater than or equal to 21'])
  end
end
