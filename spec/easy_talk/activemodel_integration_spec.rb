# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'validing json' do
  let(:user) do
    Class.new do
      include EasyTalk::Model

      validates :age, comparison: { greater_than: 21 }

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
        property :email, :object do
          property :address, String
          property :verified, T::Boolean
        end
      end
    end
  end

  it 'errors on missing email' do
    jim = user.new(name: 'Jim', age: 30, height: 5.9, email: { address: 'jim@test.com', verified: false })
    expect(jim.valid?).to be true
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
end
