# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Compositional Keywords' do
  class SomeModel
    include EasyTalk::Model

    def self.name
      'SomeModel'
    end

    define_schema do
      property :name, String
    end
  end

  class AnotherModel
    include EasyTalk::Model

    def self.name
      'AnotherModel'
    end

    define_schema do
      property :number, Integer
    end
  end

  let(:user) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'User'
      end

      define_schema do
        T::OneOf[SomeModel, AnotherModel]
      end
    end
  end

  context 'OneOf as a root node' do
    it 'returns the object with the definitions and references' do
      puts user.json_schema
      expect(user.json_schema).to include_json({
                                                 "type": 'object',
                                                 "$defs": {
                                                   "SomeModel": {
                                                     "type": 'object',
                                                     "properties": {
                                                       "name": {
                                                         "type": 'string'
                                                       }
                                                     },
                                                     "required": [
                                                       'name'
                                                     ]
                                                   },
                                                   "AnotherModel": {
                                                     "type": 'object',
                                                     "properties": {
                                                       "number": {
                                                         "type": 'integer'
                                                       }
                                                     },
                                                     "required": [
                                                       'number'
                                                     ]
                                                   }
                                                 },
                                                 "OneOf": [
                                                   {
                                                     "$ref": '#/$defs/SomeModel'
                                                   },
                                                   {
                                                     "$ref": '#/$defs/AnotherModel'
                                                   }
                                                 ]
                                               })
    end
  end

  context 'OneOf within a model property' do
    class PhoneNumber
      include EasyTalk::Model

      define_schema do
        property :phone_number, String, format: 'phone'
      end
    end

    class EmailAddress
      include EasyTalk::Model

      define_schema do
        property :email, String, format: 'email'
      end
    end

    it 'not supported yet' do
      user.define_schema do
        title 'User'
        property :contactDetail, T::OneOf[PhoneNumber, EmailAddress]
      end

      puts user.json_schema
      expect(user.json_schema).to include_json({
                                                 "type": 'object',
                                                 "title": 'User',
                                                 "properties": {
                                                   "contactDetail": {
                                                     "oneOf": [
                                                       {
                                                         "type": 'object',
                                                         "properties": {
                                                           "phone_number": {
                                                             "type": 'string',
                                                             "format": 'phone'
                                                           }
                                                         }
                                                       },
                                                       {
                                                         "type": 'object',
                                                         "properties": {
                                                           "email": {
                                                             "type": 'string',
                                                             "format": 'email'
                                                           }
                                                         }
                                                       }
                                                     ]
                                                   }
                                                 },
                                                 "required": ['contactDetail']
                                               })
    end
  end

  context 'OneOf with fields' do
    it 'not supported yet' do
      user.define_schema do
        title 'User'
        field :phone_number, String, format: 'phone'
        field :email, String, format: 'email'
        property :contactDetail, T::OneOf[:phone_number, :email]
      end

      puts user.json_schema
      expect(user.json_schema).to include_json({
                                                 "type": 'object',
                                                 "title": 'User',
                                                 "properties": {
                                                   "contactDetail": {
                                                     "oneOf": [
                                                       {
                                                         "type": 'string',
                                                         "format": 'email'
                                                       },
                                                       {
                                                         "type": 'string',
                                                         "format": 'phone'
                                                       }
                                                     ]
                                                   }
                                                 },
                                                 "required": ['contactDetail']
                                               })
    end
  end
end
