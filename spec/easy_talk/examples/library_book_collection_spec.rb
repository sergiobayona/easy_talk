# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Library Book Collection. Example using compositional keyword: not' do
  let(:book) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'Book'
      end

      define_schema do
        title 'Book'
        property :title, String, description: 'The title of the book.'
        property :author, String, description: "The name of the book's author."
        property :ISBN, String, pattern: '^(\\d{3}-?\\d{10})$', description: 'The International Standard Book Number.'
        property :publicationYear, Integer, description: 'The year the book was published.'
      end
    end
  end

  let(:magazine) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'Magazine'
      end

      define_schema do
        property :ISSN, String, pattern: '^\\d{4}-\\d{4}$', description: 'The International Standard Serial Number for periodicals.'
      end
    end
  end

  let(:expected_json_schema) do
    {
      "type": 'object',
      "title": 'Book',
      "properties": {
        "title": {
          "type": 'string',
          "description": 'The title of the book.'
        },
        "author": {
          "type": 'string',
          "description": "The name of the book's author."
        },
        "ISBN": {
          "type": 'string',
          "description": 'The International Standard Book Number.',
          "pattern": '^(\\d{3}-?\\d{10})$'
        },
        "publicationYear": {
          "type": 'integer',
          "description": 'The year the book was published.'
        }
      },
      "required": %w[
        title
        author
        ISBN
        publicationYear
      ],
      "$defs": {
        "Magazine": {
          "type": 'object',
          "properties": {
            "ISSN": {
              "type": 'string',
              "description": 'The International Standard Serial Number for periodicals.',
              "pattern": '^\\d{4}-\\d{4}$'
            }
          },
          "required": [
            'ISSN'
          ]
        }
      },
      "not": {
        "$ref": '#/$defs/Magazine'
      }
    }
  end

  pending 'returns a json schema for the book class' do
    expect(Book.json_schema).to include_json(expected_json_schema)
  end
end
