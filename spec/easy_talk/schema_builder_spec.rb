# frozen_string_literal: true

require 'spec_helper'
require 'active_record'
require 'easy_talk/schema_builder'

RSpec.describe EasyTalk::SchemaBuilder do
  before(:all) do
    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

    ActiveRecord::Schema.define do
      create_table :authors do |t|
        t.string :name, null: false, limit: 100
        t.string :email
        t.text :bio
        t.date :birth_date
        t.datetime :last_login
        t.boolean :active, default: true
        t.decimal :rating, precision: 3, scale: 2
        t.timestamps
      end

      create_table :books do |t|
        t.string :title, null: false
        t.references :author
        t.timestamps
      end
    end
  end

  let(:author_class) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'authors'
      has_many :books

      def self.name
        'Author'
      end

      def self.schema_enhancements
        @schema_enhancements ||= {}
      end

      class << self
        attr_writer :schema_enhancements
      end
    end
  end

  before do
    stub_const('Author', author_class)
    EasyTalk.instance_variable_set(:@configuration, EasyTalk::Configuration.new)
  end

  describe '#initialize' do
    it 'raises error for non-ActiveRecord class' do
      expect { described_class.new(Object) }
        .to raise_error(ArgumentError, 'Class must be an ActiveRecord model')
    end

    it 'initializes with ActiveRecord model' do
      expect { described_class.new(Author) }.not_to raise_error
    end
  end

  describe '#build' do
    subject(:schema) { described_class.new(Author).build }

    it 'includes type and title' do
      expect(schema).to include(
        'title' => 'Author',
        'type' => 'object'
      )
    end

    it 'maps column types correctly' do
      expect(schema['properties']).to include(
        'name' => {
          'type' => 'string',
          'maxLength' => 100
        },
        'active' => {
          'type' => 'boolean'
        },
        'rating' => {
          'type' => 'number'
        },
        'birth_date' => {
          'type' => 'string',
          'format' => 'date'
        },
        'last_login' => {
          'type' => 'string',
          'format' => 'date-time'
        }
      )
    end

    it 'includes required properties for non-null columns' do
      expect(schema['required']).to include('name')
    end

    context 'with excluded columns via global configuration' do
      before do
        EasyTalk.configure do |config|
          config.excluded_columns = %i[created_at updated_at]
        end
      end

      it 'excludes globally configured columns' do
        expect(schema['properties'].keys).not_to include('created_at', 'updated_at')
      end
    end

    context 'with model-specific column ignoring' do
      before do
        author_class.schema_enhancements = {
          ignore: %i[bio email]
        }
      end

      it 'excludes model-specific ignored columns' do
        expect(schema['properties'].keys).not_to include('bio', 'email')
        expect(schema['properties'].keys).to include('name', 'birth_date', 'last_login')
      end
    end

    context 'with both global and model-specific column exclusions' do
      before do
        EasyTalk.configure do |config|
          config.excluded_columns = %i[created_at updated_at]
        end

        author_class.schema_enhancements = {
          ignore: %i[bio email]
        }
      end

      it 'combines both global and model-specific exclusions' do
        expect(schema['properties'].keys).not_to include(
          'bio', 'email', 'created_at', 'updated_at'
        )
        expect(schema['properties'].keys).to include('name', 'birth_date', 'last_login')
      end
    end

    context 'with string keys in ignore array' do
      before do
        author_class.schema_enhancements = {
          ignore: %w[bio email]
        }
      end

      it 'handles string keys in ignore array properly' do
        expect(schema['properties'].keys).not_to include('bio', 'email')
      end
    end

    context 'with required properties and ignored columns' do
      before do
        author_class.schema_enhancements = {
          ignore: [:name] # name is non-null in the database
        }
      end

      it 'does not include ignored columns in required properties' do
        expect(schema['properties'].keys).not_to include('name')
        expect(schema['required']).not_to include('name')
      end
    end

    context 'with foreign keys exclusion and ignored columns' do
      before do
        EasyTalk.configure do |config|
          config.exclude_foreign_keys = true
        end

        # Using a book class for this test since it has a foreign key
        book_class = Class.new(ActiveRecord::Base) do
          self.table_name = 'books'
          belongs_to :author

          def self.name
            'Book'
          end

          def self.schema_enhancements
            @schema_enhancements ||= {}
          end

          class << self
            attr_writer :schema_enhancements
          end
        end

        stub_const('Book', book_class)
        book_class.schema_enhancements = {
          ignore: [:title]
        }
      end

      it 'respects both ignore settings and foreign keys exclusion' do
        book_schema = described_class.new(Book).build
        expect(book_schema['properties'].keys).not_to include('title', 'author_id')
      end
    end

    context 'with schema enhancements' do
      before do
        author_class.schema_enhancements = {
          title: 'Writer',
          description: 'A person who writes books',
          properties: {
            name: {
              description: "Author's pen name"
            },
            full_name: {
              virtual: true,
              type: :string,
              description: "Author's full name"
            }
          }
        }
      end

      it 'uses enhanced title and description' do
        expect(schema).to include(
          'title' => 'Writer',
          'description' => 'A person who writes books'
        )
      end

      it 'merges property enhancements with column properties' do
        expect(schema['properties']['name']).to include(
          'type' => 'string',
          'maxLength' => 100,
          'description' => "Author's pen name"
        )
      end

      it 'includes virtual properties' do
        expect(schema['properties']).to include(
          'full_name' => {
            'type' => 'string',
            'description' => "Author's full name"
          }
        )
      end
    end

    context 'with associations' do
      before do
        EasyTalk.configure { |config| config.exclude_associations = false }
      end

      it 'maps has_many to array type' do
        expect(schema['properties']['books']).to eq(
          'type' => 'array',
          'items' => { 'type' => 'object' }
        )
      end
    end

    context 'when excluding associations' do
      before do
        EasyTalk.configure { |config| config.exclude_associations = true }
      end

      it 'does not include associations' do
        expect(schema['properties']).not_to include('books')
      end
    end
  end
end
