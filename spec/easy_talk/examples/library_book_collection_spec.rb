# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Library Book Collection. Example using compositional keyword: not' do
  class Magazine
    include EasyTalk::Model

    define_schema do
      property :ISSN, String, pattern: '^\\d{4}-\\d{4}$', description: 'The International Standard Serial Number for periodicals.'
    end
  end

  class Book
    include EasyTalk::Model

    define_schema do
      title 'Book'
      property :title, String, description: 'The title of the book.'
      property :author, String, description: "The name of the book's author."
      property :ISBN, String, pattern: '^(\\d{3}-?\\d{10})$', description: 'The International Standard Book Number.'
      property :publicationYear, Integer, description: 'The year the book was published.'
      # not_schema(Magazine)
    end
  end

  context 'json schema' do
    it 'returns a json schema for the book class' do
      expect(Book.json_schema).to include_json({
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
                                               })
    end
  end
end
