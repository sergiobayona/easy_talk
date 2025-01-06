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

  pending 'errors on missing email' do
    jim = user.new(name: 'Jim', age: 30, height: 5.9)
    expect(jim.valid?).to be false
    expect(jim.errors.size).to eq(1)
    expect(jim.errors[:email]).to eq(['object at root is missing required properties: email'])
  end

  pending 'errors on invalid age, missing email' do
    jim = user.new(name: 'Jim', age: 'thirty', height: 4.5, email: { address: 'test@jim.com', verified: 'true' })
    expect(jim.valid?).to be false
    expect(jim.errors.size).to eq(1)
    expect(jim.errors[:age]).to eq(['value at `/age` is not an integer'])
  end

  pending 'errors on missing age email and height' do
    jim = user.new(name: 'Jim', email: { address: 'jim@tst.com', verified: 'true' })
    expect(jim.valid?).to be false
    expect(jim.errors.size).to eq(2)
    expect(jim.errors[:age]).to eq(['object at root is missing required properties: age'])
    expect(jim.errors[:height]).to eq(['object at root is missing required properties: height'])
  end

  pending 'errors on invalid name, email and age' do
    jim = user.new(name: nil, email: 'test@jim', age: 'thirty')
    expect(jim.valid?).to be false
    expect(jim.errors[:name]).to eq(['value at `/name` is not a string'])
    expect(jim.errors[:email]).to eq(['value at `/email` is not an object'])
    expect(jim.errors[:age]).to eq(['value at `/age` is not an integer'])
  end

  pending 'errors on verified' do
    jim = user.new(name: 'Jim', email: { address: 'test@jim.com', verified: false }, age: 21, height: 5.9)
    expect(jim.valid?).to be(false)
    expect(jim.errors['email.verified']).to eq(['value at `/email/verified` is not a string'])
  end
end
