# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'validing json' do
  let(:user) do
    Class.new do
      include EasyTalk::Model

      validates :age, comparison: { greater_than: 21 }
      validates :height, presence: true, numericality: { greater_than: 0 }

      validate do |person|
        MyValidator.new(person).validate
      end

      class MyValidator
        def initialize(person)
          @person = person
        end

        def validate
          @person.errors.add(:email, 'must end with @test.com') unless @person.email[:address].ends_with?('@test.com')
        end
      end

      def self.name
        'User'
      end

      define_schema do
        property :name, String
        property :age, Integer
        property :height, Float
        property :email, Hash do
          property :address, String
          property :verified, T::Boolean
        end
      end
    end
  end

  describe 'validating properties without ActiveModel validations' do
    it 'does not validate the nil name' do
      jim = user.new(name: nil, age: 30, height: 5.9, email: { address: 'jim@test.com', verified: false })
      expect(jim.valid?).to be true
    end

    it 'does not validate the empty name' do
      jim = user.new(name: '', age: 30, height: 5.9, email: { address: 'jim@test.com', verified: false })
      expect(jim.valid?).to be true
    end

    it 'does not validate the property that is not present' do
      jim = user.new(age: 30, height: 5.9, email: { address: 'jim@test.com', verified: false })
      expect(jim.valid?).to be true
    end
  end

  it 'is valid' do
    jim = user.new(name: 'Jim', age: 30, height: 5.9, email: { address: 'jim@test.com', verified: false })
    expect(jim.valid?).to be true
    expect(jim.errors.size).to eq(0)
  end

  it 'errors on invalid age' do
    jim = user.new(name: 'Jim', age: 18, height: 5.9, email: { address: 'jim@test.com', verified: false })
    expect(jim.valid?).to be false
    expect(jim.errors.size).to eq(1)
    expect(jim.errors[:age]).to eq(['must be greater than 21'])
  end

  it 'errors on invalid email' do
    jim = user.new(name: 'Jim', age: 30, height: 5.9, email: { address: 'jim@gmail.com', verified: false })
    expect(jim.valid?).to be false
    expect(jim.errors.size).to eq(1)
    expect(jim.errors[:email]).to eq(['must end with @test.com'])
  end

  it 'errors on missing height' do
    jim = user.new(name: 'Jim', age: 30, email: { address: 'jim@gmailcom', verified: false })
    expect(jim.valid?).to be false
    expect(jim.errors[:height]).to eq(["can't be blank", 'is not a number'])
  end

  it 'errors on invalid height' do
    jim = user.new(name: 'Jim', age: 30, height: -5.9, email: { address: 'jim@gmailcom', verified: false })
    expect(jim.valid?).to be false
    expect(jim.errors[:height]).to eq(['must be greater than 0'])
  end

  it 'responds to #invalid?' do
    jim = user.new(name: 'Jim', age: 18, height: 5.9, email: { address: 'jim@test.com', verified: false })
    expect(jim.invalid?).to be true
  end

  it 'responds to #errors' do
    jim = user.new(name: 'Jim', age: 18, height: 5.9, email: { address: 'jim@test.com', verified: false })
    jim.valid?
    expect(jim.errors).to be_a(ActiveModel::Errors)
  end

  it 'responds to #errors.messages' do
    jim = user.new(name: 'Jim', age: 18, height: 5.9, email: { address: 'jim@test.com', verified: false })
    jim.valid?
    expect(jim.errors.messages).to eq(age: ['must be greater than 21'])
  end
end
