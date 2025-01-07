# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User routing table' do
  let(:user_routing) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'User Routing'
      end

      define_schema do
        property 'user_id', Hash do
          description 'Get a user by id'
          property :phrases, T::Array[String],
                   title: 'trigger phrase examples',
                   description: 'Examples of phrases that trigger this route',
                   enum: [
                     'find user with id {id}',
                     'search for user by id {id}',
                     'user id {id}'
                   ]
          property :parameter, Hash do
            property :id, String, description: 'The user id'
          end
          property :path, String, description: 'The route path to get the user by id'
        end
        property 'user_email', Hash do
          description 'Get a user by email'
          property :phrases, T::Array[String],
                   title: 'trigger phrase examples',
                   description: 'Examples of phrases that trigger this route',
                   enum: [
                     'find user with email {email}',
                     'search for user by email {email}',
                     'user email {email}'
                   ]
          property :parameter, Hash do
            property :email, String, description: 'the user email address'
          end
          property :path, String, const: 'user/:email', description: 'The route path to get the user by email'
        end
        property 'user_id_authenticate', Hash do
          description 'Authenticate a user'
          property :phrases, T::Array[String],
                   title: 'trigger phrase examples',
                   description: 'Examples of phrases that trigger this route',
                   enum: [
                     'authenticate user with id {id}',
                     'authenticate user id {id}',
                     'authenticate user {id}'
                   ]
          property :parameters, Hash do
            property :id, String, description: 'the user id'
          end
          property :path, String, const: 'user/:id/authenticate', description: 'The route path to authenticate a user'
        end
      end
    end
  end

  let(:expected_json_schema) do
    {
      "type": 'object',
      "properties": {
        "user_id": {
          "type": 'object',
          "description": 'Get a user by id',
          "properties": {
            "phrases": {
              "type": 'array',
              "items": {
                "type": 'string'
              },
              "title": 'trigger phrase examples',
              "description": 'Examples of phrases that trigger this route',
              "enum": [
                'find user with id {id}',
                'search for user by id {id}',
                'user id {id}'
              ]
            },
            "parameter": {
              "type": 'object',
              "properties": {
                "id": {
                  "type": 'string',
                  "description": 'The user id'
                }
              },
              "required": [
                'id'
              ]
            },
            "path": {
              "type": 'string',
              "description": 'The route path to get the user by id'
            }
          },
          "required": %w[
            phrases
            parameter
            path
          ]
        },
        "user_email": {
          "type": 'object',
          "description": 'Get a user by email',
          "properties": {
            "phrases": {
              "type": 'array',
              "items": {
                "type": 'string'
              },
              "title": 'trigger phrase examples',
              "description": 'Examples of phrases that trigger this route',
              "enum": [
                'find user with email {email}',
                'search for user by email {email}',
                'user email {email}'
              ]
            },
            "parameter": {
              "type": 'object',
              "properties": {
                "email": {
                  "type": 'string',
                  "description": 'the user email address'
                }
              },
              "required": [
                'email'
              ]
            },
            "path": {
              "type": 'string',
              "description": 'The route path to get the user by email',
              "const": 'user/:email'
            }
          },
          "required": %w[
            phrases
            parameter
            path
          ]
        },
        "user_id_authenticate": {
          "type": 'object',
          "description": 'Authenticate a user',
          "properties": {
            "phrases": {
              "type": 'array',
              "items": {
                "type": 'string'
              },
              "title": 'trigger phrase examples',
              "description": 'Examples of phrases that trigger this route',
              "enum": [
                'authenticate user with id {id}',
                'authenticate user id {id}',
                'authenticate user {id}'
              ]
            },
            "parameters": {
              "type": 'object',
              "properties": {
                "id": {
                  "type": 'string',
                  "description": 'the user id'
                }
              },
              "required": [
                'id'
              ]
            },
            "path": {
              "type": 'string',
              "description": 'The route path to authenticate a user',
              "const": 'user/:id/authenticate'
            }
          },
          "required": %w[
            phrases
            parameters
            path
          ]
        }
      },
      "required": %w[
        user_id
        user_email
        user_id_authenticate
      ]
    }
  end

  it 'returns a json schema for the book class' do
    stub_const('UserRouting', user_routing)
    expect(UserRouting.json_schema).to include_json(expected_json_schema)
  end
end
