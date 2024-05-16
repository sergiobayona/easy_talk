# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'optional properties' do
  let(:user) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'User'
      end

      define_schema do
        property :name, String
        property :age, Integer
        property :email, :object do
          property :address, String
          property :verified, String
        end
      end
    end
  end

  it 'returns all properties as required' do
    base_level_requires = user.json_schema['required']
    nested_level_requires = user.json_schema['properties']['email']['required']

    expect(base_level_requires).to eq(%w[name age email])
    expect(nested_level_requires).to eq(%w[address verified])
  end

  context 'when using the optional constraint' do
    describe 'with a property on a nested object' do
      let(:user) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'User'
          end

          define_schema do
            property :name, String
            property :age, Integer
            property :email, :object do
              property :address, String
              property :verified, String, optional: true
            end
          end
        end
      end

      it 'excludes the optional nested property' do
        base_level_requires = user.json_schema['required']
        nested_level_requires = user.json_schema['properties']['email']['required']

        expect(base_level_requires).to eq(%w[name age email])
        expect(nested_level_requires).to eq(%w[address])
      end
    end

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
            property :email, :object do
              property :address, String
              property :verified, String
            end
          end
        end
      end

      it 'excludes the optional property' do
        base_level_requires = user.json_schema['required']
        nested_level_requires = user.json_schema['properties']['email']['required']

        expect(base_level_requires).to eq(%w[name email])
        expect(nested_level_requires).to eq(%w[address verified])
      end
    end

    describe 'with a block-style prop' do
      let(:user) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'User'
          end

          define_schema do
            property :name, String
            property :age, Integer
            property :email, :object, optional: true do
              property :address, String
              property :verified, String
            end
          end
        end
      end

      it 'excludes the optional block-style property' do
        base_level_requires = user.json_schema['required']
        nested_level_requires = user.json_schema['properties']['email']['required']
        expect(base_level_requires).to eq(%w[name age])
        expect(nested_level_requires).to eq(%w[address verified])
      end
    end
  end

  context 'when using the T.nilable type' do
    let(:user) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'User'
        end

        define_schema do
          property :name, String
          property :age, T.nilable(Integer)
          property :email, :object do
            property :address, String
            property :verified, String
          end
        end
      end
    end

    it 'excludes the nilable property' do
      base_level_requires = user.json_schema['required']
      nested_level_requires = user.json_schema['properties']['email']['required']

      expect(base_level_requires).to eq(%w[name email])
      expect(nested_level_requires).to eq(%w[address verified])
    end

    context 'with a compound model' do
      let(:email) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'Email'
          end

          define_schema do
            property :address, String
            property :verified, String
          end
        end
      end

      let(:user) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'User'
          end
        end
      end

      it 'excludes the nilable property' do
        stub_const('User', user)
        stub_const('Email', email)

        User.define_schema do
          property :name, String
          property :age, Integer
          property :email, T.nilable(Email)
        end
        base_level_requires = User.json_schema['required']
        nested_level_requires = User.json_schema['properties']['email']['required']

        puts User.json_schema
        expect(base_level_requires).to eq(%w[name age])
        expect(nested_level_requires).to eq(%w[address verified])
      end
    end
  end
end
