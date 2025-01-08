# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'attribute accessors' do
  let(:user) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'User'
      end

      define_schema do
        property :name, String
        property :age, Integer
        property :email, Hash do
          property :address, String
          property :verified, T::Boolean
        end
      end
    end
  end

  it 'creates a getter and setter for name' do
    jim = user.new
    expect(jim.name = 'Jim').to eq('Jim')
    expect(jim.name).to eq('Jim')

    jim.name = 'Juan'
    expect(jim.name).to eq('Juan')
  end

  it 'creates a getter and setter for age' do
    jim = user.new
    expect(jim.age = 30).to eq(30)
    expect(jim.age).to eq(30)
    jim.age = '30' ## does not raise an error.
    expect(jim.age).to eq('30') ## no coercion yet.
  end

  it 'creates a getter and setter for email' do
    jim = user.new
    jim.email = { address: 'jim@test.com', verified: false }
    expect(jim.email).to eq({ address: 'jim@test.com', verified: false })
  end

  it "raises exception when assigning a value to a property that doesn't exist" do
    jim = user.new
    expect { jim.height = 5.9 }.to raise_error(NoMethodError)
  end

  it 'raises exception when accessing a property that does not exist' do
    jim = user.new
    expect { jim.height }.to raise_error(NoMethodError)
  end

  it 'allows hash style assignment' do
    jim = user.new(name: 'Jim', age: 30, email: { address: 'jim@test.com', verified: false })
    expect(jim.name).to eq('Jim')
    expect(jim.age).to eq(30)
    expect(jim.email).to eq({ address: 'jim@test.com', verified: false })
  end
end
