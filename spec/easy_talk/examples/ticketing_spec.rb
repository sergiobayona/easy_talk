# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Ticketing system' do
  let(:subtask) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'Subtask'
      end

      define_schema do
        property :id, Integer, description: 'Unique identifier for the subtask'
        property :name, String, description: 'Title of the subtask'
      end
    end
  end
  let(:expected_json_schema) do
    {
      type: 'object',
      title: 'Action Items',
      description: 'A list of action items',
      properties: {
        items: {
          type: 'array',
          items: {
            type: 'object',
            title: 'Ticket',
            properties: {
              id: {
                type: 'integer',
                description: 'Unique identifier for the ticket'
              },
              name: {
                type: 'string',
                description: 'Title of the ticket'
              },
              description: {
                type: 'string',
                description: 'Detailed description of the task'
              },
              priority: {
                type: 'string',
                description: 'Priority level',
                enum: %w[
                  High
                  Medium
                  Low
                ]
              },
              assignees: {
                type: 'array',
                items: {
                  type: 'string'
                },
                description: 'List of users assigned to the task'
              },
              subtasks: {
                anyOf: [
                  {
                    type: 'array',
                    items: {
                      type: 'object',
                      properties: {
                        id: {
                          type: 'integer',
                          description: 'Unique identifier for the subtask'
                        },
                        name: {
                          type: 'string',
                          description: 'Title of the subtask'
                        }
                      },
                      required: %w[
                        id
                        name
                      ]
                    },
                    description: 'List of subtasks associated with the main task'
                  },
                  {
                    type: 'null'
                  }
                ]
              },
              dependencies: {
                anyOf: [
                  {
                    type: 'array',
                    items: {
                      type: 'integer'
                    },
                    description: 'List of ticket IDs that this ticket depends on'
                  },
                  {
                    type: 'null'
                  }
                ]
              }
            },
            required: %w[
              id
              name
              description
              priority
              assignees
            ]
          }
        }
      },
      required: [
        'items'
      ]
    }
  end
  let(:action_items) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'ActionItems'
      end
    end
  end

  let(:ticket) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'Ticket'
      end
    end
  end

  it 'returns a json schema for a list of action items' do
    stub_const('ActionItems', action_items)
    stub_const('Ticket', ticket)
    stub_const('Subtask', subtask)

    Ticket.define_schema do
      title 'Ticket'
      property :id, Integer, description: 'Unique identifier for the ticket'
      property :name, String, description: 'Title of the ticket'
      property :description, String, description: 'Detailed description of the task'
      property :priority, String, enum: %w[High Medium Low], description: 'Priority level'
      property :assignees, T::Array[String], description: 'List of users assigned to the task'
      property :subtasks, T.nilable(T::Array[Subtask]), description: 'List of subtasks associated with the main task'
      property :dependencies, T.nilable(T::Array[Integer]), description: 'List of ticket IDs that this ticket depends on'
    end

    ActionItems.define_schema do
      title 'Action Items'
      description 'A list of action items'
      property :items, T::Array[Ticket]
    end

    expect(ActionItems.json_schema).to include_json(expected_json_schema)
  end
end
