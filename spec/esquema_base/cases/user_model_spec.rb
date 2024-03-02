# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'json for user model' do
  let(:user) do
    Class.new do
      include EsquemaBase::Model
    end
  end

  describe '.schema_definition' do
    it 'returns the schema definition' do
      expect(user.json_schema).to include_json({})
    end
  end

  describe '.json_schema' do
    class Phone
      include EsquemaBase::Model
      define_schema do
        title 'Phone'
        description 'A phone number'
        property 'number', String, title: 'Phone Number', format: 'phone'
        property 'type', String, title: 'Phone Type'
      end
    end

    it 'enhances the schema using the provided block' do
      user.define_schema do
        title 'User'
        description 'A user of the system'
        property 'name', String, title: "Person's Name"
        property 'email', String, format: 'email', title: "Person's email"
        property 'dob', Date, title: 'Date of Birth'
        property 'group', Integer, enum: [1, 2, 3], default: 1
        property 'phones', T::Array[Phone], title: 'Phones'
        property 'tags', T::Array[String], title: 'Tags'
      end
      puts user.json_schema
      expect(user.json_schema).to include_json({
                                                 "title": 'User',
                                                 "description": 'A user of the system',
                                                 "type": 'object',
                                                 "properties": {
                                                   "name": {
                                                     "type": 'string',
                                                     "title": "Person's Name"
                                                   },
                                                   "email": {
                                                     "type": 'string',
                                                     "title": "Person's Mailing Address",
                                                     "format": 'email'
                                                   },
                                                   "dob": {
                                                     "type": 'string',
                                                     "format": 'date',
                                                     "title": 'Date of Birth'
                                                   },
                                                   "group": {
                                                     "type": 'integer',
                                                     "enum": [
                                                       1,
                                                       2,
                                                       3
                                                     ],
                                                     "default": 1
                                                   },
                                                   "phones": {
                                                     "type": 'array',
                                                     "items": {
                                                       "title": 'Phone',
                                                       "description": 'A phone number',
                                                       "type": 'object',
                                                       "properties": {
                                                         "number": {
                                                           "type": 'string',
                                                           "title": 'Phone Number',
                                                           "format": 'phone'
                                                         },
                                                         "type": {
                                                           "type": 'string',
                                                           "title": 'Phone Type'
                                                         }
                                                       },
                                                       "required": %w[
                                                         number
                                                         type
                                                       ]
                                                     },
                                                     "title": 'Phones'
                                                   },
                                                   "tags": {
                                                     "type": 'array',
                                                     "items": {
                                                       "type": 'string'
                                                     },
                                                     "title": 'Tags'
                                                   }
                                                 },
                                                 "required": %w[
                                                   name
                                                   email
                                                   dob
                                                   group
                                                   phones
                                                   tags
                                                 ]
                                               })
    end
  end
end
