# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Auto Validations' do
  let(:user_class) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'User'
      end

      define_schema do
        property :name, String, min_length: 2, max_length: 50
        property :email, String, format: 'email'
        property :age, Integer, minimum: 18, maximum: 120
        property :gender, String, enum: %w[male female other]
        property :tags, T::Array[String], min_items: 1, max_items: 5
        property :active, T::Boolean
      end
    end
  end

  before do
    # Enable auto-validations for testing
    EasyTalk.configure { |config| config.auto_validations = true }
  end

  describe 'string validations' do
    it 'validates string length' do
      user = user_class.new(name: 'A')
      expect(user.valid?).to be(false)
      expect(user.errors[:name]).to include('is too short (minimum is 2 characters)')

      user.name = 'A' * 51
      expect(user.valid?).to be(false)
      expect(user.errors[:name]).to include('is too long (maximum is 50 characters)')

      user.name = 'Valid Name'
      # Clear previous errors for this field
      user.errors.delete(:name)
      user.validate
      expect(user.errors[:name]).to be_empty
    end

    it 'validates email format' do
      user = user_class.new(email: 'not-an-email')
      expect(user.valid?).to be(false)
      expect(user.errors[:email]).to include('must be a valid email address')

      user.email = 'valid@example.com'
      # Clear previous errors for this field
      user.errors.delete(:email)
      user.validate
      expect(user.errors[:email]).to be_empty
    end

    it 'validates enum inclusion' do
      user = user_class.new(gender: 'invalid')
      expect(user.valid?).to be(false)
      expect(user.errors[:gender]).to include('must be one of: male, female, other')

      user.gender = 'male'
      # Clear previous errors for this field
      user.errors.delete(:gender)
      user.validate
      expect(user.errors[:gender]).to be_empty
    end
  end

  describe 'numeric validations' do
    it 'validates numeric range' do
      user = user_class.new(age: 17)
      expect(user.valid?).to be(false)
      expect(user.errors[:age]).to include('must be greater than or equal to 18')

      user.age = 121
      expect(user.valid?).to be(false)
      expect(user.errors[:age]).to include('must be less than or equal to 120')

      user.age = 25
      # Clear previous errors for this field
      user.errors.delete(:age)
      user.validate
      expect(user.errors[:age]).to be_empty
    end
  end

  describe 'array validations' do
    it 'validates array length' do
      user = user_class.new(tags: [])
      expect(user.valid?).to be(false)
      expect(user.errors[:tags]).to include('is too short (minimum is 1 character)')

      user.tags = %w[tag1 tag2 tag3 tag4 tag5 tag6]
      expect(user.valid?).to be(false)
      expect(user.errors[:tags]).to include('is too long (maximum is 5 characters)')

      user.tags = %w[tag1 tag2]
      # Clear previous errors for this field
      user.errors.delete(:tags)
      user.validate
      expect(user.errors[:tags]).to be_empty
    end
  end

  describe 'boolean validations' do
    it 'validates boolean type' do
      user = user_class.new(active: 'yes') # Not a boolean
      expect(user.valid?).to be(false)
      expect(user.errors[:active]).to include('is not included in the list')

      user.active = true
      # Clear previous errors for this field
      user.errors.delete(:active)
      user.validate
      expect(user.errors[:active]).to be_empty
    end
  end

  describe 'presence validations' do
    it 'validates required fields' do
      user = user_class.new
      expect(user.valid?).to be(false)
      expect(user.errors[:name]).to include("can't be blank")
      expect(user.errors[:email]).to include("can't be blank")
      expect(user.errors[:age]).to include("can't be blank")
      expect(user.errors[:gender]).to include("can't be blank")
      expect(user.errors[:tags]).to include("can't be blank")
      expect(user.errors[:active]).to include("can't be blank")
    end
  end

  describe 'disabling auto-validations' do
    before do
      EasyTalk.configure { |config| config.auto_validations = false }
    end

    after do
      EasyTalk.configure { |config| config.auto_validations = true }
    end

    it 'does not generate validations when disabled' do
      # Create a fresh class with auto-validations disabled
      test_class = Class.new do
        include EasyTalk::Model

        def self.name
          'TestClass'
        end

        define_schema do
          property :name, String, min_length: 2
        end
      end

      instance = test_class.new(name: 'A')
      # With validations disabled, this should pass even though name is too short
      expect(instance.valid?).to be(true)
    end
  end

  describe 'optional properties' do
    let(:optional_class) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'OptionalProps'
        end

        define_schema do
          property :required_name, String
          property :optional_name, String, optional: true
          property :nilable_name, T.nilable(String)
        end
      end
    end

    it 'does not require optional properties' do
      EasyTalk.configure { |config| config.nilable_is_optional = false }
      instance = optional_class.new(required_name: 'Present')

      # When nilable_is_optional is false, we expect nilable_name to be required
      # but optional_name should still be optional due to explicit optional: true flag
      expect(instance.errors[:optional_name]).to be_empty

      instance.nilable_name = nil
      expect(instance.valid?).to be(true)
    end

    it 'treats nilable as optional when configured' do
      EasyTalk.configure { |config| config.nilable_is_optional = true }
      instance = optional_class.new(required_name: 'Present')

      expect(instance.valid?).to be(true)
      expect(instance.errors[:nilable_name]).to be_empty
    end
  end
end
