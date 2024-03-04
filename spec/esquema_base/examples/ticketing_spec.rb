# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Ticketing system' do
  class Subtask
    include EsquemaBase::Model

    define_schema do
      property 'id', Integer, description: 'Unique identifier for the subtask'
      property 'name', String, description: 'Title of the subtask'
    end
  end

  class Ticket
    include EsquemaBase::Model

    define_schema do
      property 'id', Integer, description: 'Unique identifier for the ticket'
      property 'name', String, description: 'Title of the ticket'
      property 'description', String, description: 'Detailed description of the task'
      property 'priority', String, enum: %w[High Meidum Low], description: 'Priority level'
      property 'assignees', T::Array[String], description: 'List of users assigned to the task'
      property 'subtasks', T::Array[T.nilable(Subtask)], optional: true,
                                                         description: 'List of subtasks associated with the main task'
      property 'dependencies', T::Array[Integer], optional: true,
                                                  description: 'List of ticket IDs that this ticket depends on'
    end
  end

  class ActionItems
    include EsquemaBase::Model

    define_schema do
      title 'Action Items'
      description 'A list of action items'
      property 'items', T::Array[Ticket]
    end
  end

  context 'json schema' do
    it 'returns a json schema for a list of action items' do
      expect(ActionItems.json_schema).to include_json({
                                                        "title": 'Action Items',
                                                        "description": 'A list of action items',
                                                        "type": 'object',
                                                        "properties": {
                                                          "items": {
                                                            "type": 'array',
                                                            "items": {
                                                              "type": 'object',
                                                              "properties": {
                                                                "id": {
                                                                  "type": 'integer',
                                                                  "description": 'Unique identifier for the ticket'
                                                                },
                                                                "name": {
                                                                  "type": 'string',
                                                                  "description": 'Title of the ticket'
                                                                },
                                                                "description": {
                                                                  "type": 'string',
                                                                  "description": 'Detailed description of the task'
                                                                },
                                                                "priority": {
                                                                  "type": 'string',
                                                                  "description": 'Priority level',
                                                                  "enum": %w[
                                                                    High
                                                                    Meidum
                                                                    Low
                                                                  ]
                                                                },
                                                                "assignees": {
                                                                  "type": 'array',
                                                                  "items": {
                                                                    "type": 'string'
                                                                  },
                                                                  "description": 'List of users assigned to the task'
                                                                },
                                                                "subtasks": {
                                                                  "type": 'array',
                                                                  "items": {
                                                                    "anyOf": [
                                                                      {
                                                                        "type": 'object',
                                                                        "properties": {
                                                                          "id": {
                                                                            "type": 'integer',
                                                                            "description": 'Unique identifier for the subtask'
                                                                          },
                                                                          "name": {
                                                                            "type": 'string',
                                                                            "description": 'Title of the subtask'
                                                                          }
                                                                        },
                                                                        "required": %w[
                                                                          id
                                                                          name
                                                                        ]
                                                                      },
                                                                      {
                                                                        "type": 'null'
                                                                      }
                                                                    ]
                                                                  },
                                                                  "description": 'List of subtasks associated with the main task',
                                                                  "": true
                                                                },
                                                                "dependencies": {
                                                                  "type": 'array',
                                                                  "items": {
                                                                    "type": 'integer'
                                                                  },
                                                                  "description": 'List of ticket IDs that this ticket depends on',
                                                                  "": true
                                                                }
                                                              },
                                                              "required": %w[
                                                                id
                                                                name
                                                                description
                                                                priority
                                                                assignees
                                                              ]
                                                            }
                                                          }
                                                        },
                                                        "required": [
                                                          'items'
                                                        ]
                                                      })
    end
  end
end
