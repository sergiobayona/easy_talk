require 'spec_helper'
require 'active_record'

RSpec.describe EasyTalk::ActiveRecordModel do
  before(:all) do
    ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

    ActiveRecord::Schema.define do
      create_table :posts do |t|
        t.string :title, null: false
        t.text :content
        t.boolean :published, default: false
        t.timestamps
      end
    end
  end

  let(:post_class) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'posts'

      def self.name
        'Post'
      end
    end
  end

  before do
    stub_const('Post', post_class)
  end

  describe '.included' do
    it 'adds class methods when included' do
      post_class.include(described_class)
      expect(post_class).to respond_to(:json_schema)
      expect(post_class).to respond_to(:schema_enhancements)
      expect(post_class).to respond_to(:enhance_schema)
    end
  end

  context 'when included in model' do
    before do
      post_class.include(described_class)
    end

    describe '.json_schema' do
      it 'returns schema for model' do
        expect(post_class.json_schema).to include(
          type: 'object',
          title: 'Post',
          properties: include(
            'title' => include(type: 'string'),
            'content' => include(type: 'string'),
            'published' => include(type: 'boolean')
          )
        )
      end

      it 'caches the schema' do
        schema1 = post_class.json_schema
        schema2 = post_class.json_schema
        expect(schema1).to be(schema2)
      end
    end

    describe '.schema_enhancements' do
      it 'starts with empty enhancements' do
        expect(post_class.schema_enhancements).to eq({})
      end

      it 'maintains enhancements between calls' do
        post_class.enhance_schema(title: 'Blog Post')
        expect(post_class.schema_enhancements[:title]).to eq('Blog Post')
      end
    end

    describe '.enhance_schema' do
      it 'allows setting schema title' do
        post_class.enhance_schema(title: 'Blog Post')
        expect(post_class.json_schema[:title]).to eq('Blog Post')
      end

      it 'allows setting schema description' do
        post_class.enhance_schema(description: 'A blog post')
        expect(post_class.json_schema[:description]).to eq('A blog post')
      end

      it 'allows adding virtual properties' do
        post_class.enhance_schema(
          properties: {
            word_count: {
              virtual: true,
              type: :integer,
              description: 'Number of words in content'
            }
          }
        )

        expect(post_class.json_schema[:properties]).to include(
          'word_count' => include(
            type: 'integer',
            description: 'Number of words in content'
          )
        )
      end

      it 'allows enhancing existing properties' do
        post_class.enhance_schema(
          properties: {
            title: {
              description: 'The title of the blog post'
            }
          }
        )

        expect(post_class.json_schema[:properties]['title']).to include(
          description: 'The title of the blog post'
        )
      end

      it 'overwrites previous enhancements' do
        post_class.enhance_schema(title: 'Blog Post')
        post_class.enhance_schema(title: 'Article')
        expect(post_class.json_schema[:title]).to eq('Article')
      end

      it 'resets schema cache when called' do
        original_schema = post_class.json_schema
        post_class.enhance_schema(title: 'New Title')
        new_schema = post_class.json_schema

        expect(new_schema).not_to be(original_schema)
        expect(new_schema[:title]).to eq('New Title')
      end
    end
  end
end
