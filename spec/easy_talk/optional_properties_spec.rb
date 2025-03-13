# frozen_string_literal: true

require 'spec_helper'
require 'easy_talk/model'

RSpec.describe 'optional properties' do
  before do
    EasyTalk.configure do |config|
      config.nilable_is_optional = false
    end

    # Define the Email class for use in the tests
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
        property :email, String, optional: true
        property :age, T.nilable(Integer)
      end
    end
  end

  context 'with nilable_is_optional = false' do
    it 'excludes optional but includes nilable' do
      json_schema = user.json_schema
      required = json_schema['required']

      # Check that the optional property is not required
      expect(required).not_to include('email')
      # But the nilable one is
      expect(required).to include('age')
    end
  end

  context 'with nilable_is_optional = true' do
    before do
      EasyTalk.configure do |config|
        config.nilable_is_optional = true
      end
    end

    it 'excludes both optional and nilable' do
      json_schema = user.json_schema
      required = json_schema['required']

      # Both optional and nilable properties should be excluded
      expect(required).not_to include('email')
      expect(required).not_to include('age')
    end
  end

  describe 'with nested schemas' do
    describe 'with a prop at the top level' do
      let(:user) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'User'
          end

          define_schema do
            property :name, String
            property :age, Integer, optional: true
            property :email, Email
          end
        end
      end

      it 'excludes the optional property' do
        base_level_requires = user.json_schema['required']
        expect(base_level_requires).to eq(%w[name email])
      end
    end

    describe 'with a class reference property' do
      let(:user) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'User'
          end

          define_schema do
            property :name, String
            property :age, Integer
            property :email, Email, optional: true
          end
        end
      end

      it 'excludes the optional class reference property' do
        base_level_requires = user.json_schema['required']
        expect(base_level_requires).to eq(%w[name age])
      end
    end
  end

  describe 'block-style sub-schemas' do
    it 'raises an error when using block-style sub-schemas' do
      user_class = Class.new do
        include EasyTalk::Model

        def self.name
          'User'
        end
      end

      expect do
        user_class.define_schema do
          property :email, Hash do
            property :address, String
          end
        end
      end.to raise_error(ArgumentError, 'Block-style sub-schemas are no longer supported. Use class references as types instead.')
    end
  end
end
