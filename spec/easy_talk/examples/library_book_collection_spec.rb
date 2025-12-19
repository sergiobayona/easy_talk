# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Library Book Collection' do
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
        property :isbn, String, pattern: '\A(\d{3}-?\d{10})\z', description: 'The International Standard Book Number.', as: :ISBN
        property :publication_year, Integer, description: 'The year the book was published.'
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
        property :issn, String, pattern: '\A\d{4}-\d{4}\z', description: 'The International Standard Serial Number for periodicals.', as: :ISSN
      end
    end
  end

  let(:expected_book_schema) do
    {
      type: 'object',
      title: 'Book',
      properties: {
        title: {
          type: 'string',
          description: 'The title of the book.'
        },
        author: {
          type: 'string',
          description: "The name of the book's author."
        },
        ISBN: {
          type: 'string',
          description: 'The International Standard Book Number.',
          pattern: '^(\d{3}-?\d{10})$'
        },
        publicationYear: {
          type: 'integer',
          description: 'The year the book was published.'
        }
      },
      required: %w[
        title
        author
        ISBN
        publicationYear
      ]
    }
  end

  let(:expected_magazine_schema) do
    {
      type: 'object',
      properties: {
        ISSN: {
          type: 'string',
          description: 'The International Standard Serial Number for periodicals.',
          pattern: '^\d{4}-\d{4}$'
        }
      },
      required: [
        'ISSN'
      ]
    }
  end

  before { EasyTalk.configure { |config| config.property_naming_strategy = :camel_case } }
  after { EasyTalk.configure { |config| config.property_naming_strategy = :identity } }

  it 'returns a json schema for the book class' do
    expect(book.json_schema).to include_json(expected_book_schema)
  end

  it 'returns a json schema for the magazine class' do
    expect(magazine.json_schema).to include_json(expected_magazine_schema)
  end
end
