# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'EasyTalk::Schema mutable default values shared across instances' do
  # EasyTalk::Model fixed this in PR #165 by using EasyTalk.deep_dup(default_value).
  # EasyTalk::Schema has identical initialization logic but was never patched:
  #
  #   default_value = prop_definition.dig(:constraints, :default)
  #   value = default_value unless default_value.nil?   # ← no deep_dup
  #
  # The raw object from the schema cache is assigned directly to every instance,
  # so mutating the default on one instance silently corrupts all others.

  context 'with an Array default' do
    let(:schema_class) do
      Class.new do
        include EasyTalk::Schema

        def self.name = 'Contract'

        define_schema do
          property :tags, T::Array[String], default: []
        end
      end
    end

    it 'gives each instance its own copy of the default array' do
      a = schema_class.new
      b = schema_class.new

      a.tags << 'urgent'

      expect(b.tags).to eq([]),
                        "b.tags was corrupted by a mutation: #{b.tags.inspect}. " \
                        'The mutable default array is shared across instances.'
    end

    it 'does not share the same object between instances' do
      a = schema_class.new
      b = schema_class.new

      expect(a.tags.object_id).not_to eq(b.tags.object_id),
                                      'Both instances reference the identical Array object for :tags'
    end
  end

  context 'with a Hash default' do
    let(:schema_class) do
      Class.new do
        include EasyTalk::Schema

        def self.name = 'MetaContract'

        define_schema do
          property :metadata, String, default: { 'env' => 'production' }
        end
      end
    end

    it 'gives each instance its own copy of the default hash' do
      a = schema_class.new
      b = schema_class.new

      a.metadata['injected'] = 'surprise'

      expect(b.metadata).to eq({ 'env' => 'production' }),
                            "b.metadata was corrupted by a mutation: #{b.metadata.inspect}. " \
                            'The mutable default hash is shared across instances.'
    end
  end
end
