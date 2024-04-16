require 'spec_helper'

RSpec.describe EasyTalk::Model, 'property mapping' do
  let(:user) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'User'
      end

      define_schema do
        title 'User'
        property :name, String
        property :age, Integer
        property :email, String
        property :gender, String, enum: %w[male female]
      end
    end
  end

  it 'maps properties to the instance of the class' do
    instance = user.new({ name: 'John', age: 21, email: 'john@example.com', gender: 'male' })
    expect(instance.name).to eq('John')
    expect(instance.age).to eq(21)
    expect(instance.email).to eq('john@example.com')
    expect(instance.gender).to eq('male')
    expect(instance.valid?).to eq(true)
    expect(instance.properties).to eq({ name: 'John', age: 21, email: 'john@example.com', gender: 'male' })
  end
end
