# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'mutable default values shared across instances' do
  # This spec proves that when a property has a mutable default (Array, Hash),
  # the same object is assigned to every instance. Mutating one instance's
  # default silently corrupts all other instances.

  context 'with an Array default' do
    let(:model) do
      Class.new do
        include EasyTalk::Model

        def self.name = 'TaggedItem'

        define_schema do
          property :tags, T::Array[String], default: []
        end
      end
    end

    it 'gives each instance its own copy of the default array' do
      a = model.new
      b = model.new

      a.tags << 'hello'

      expect(b.tags).to eq([]),
                        "Instance b saw a's mutation: b.tags=#{b.tags.inspect}. " \
                        'Mutable default is shared across instances.'
    end

    it 'does not share the same object between instances' do
      a = model.new
      b = model.new

      expect(a.tags.object_id).not_to eq(b.tags.object_id),
                                      'Both instances share the exact same Array object for :tags'
    end
  end

  context 'with a Hash default' do
    let(:model) do
      Class.new do
        include EasyTalk::Model

        def self.name = 'MetadataItem'

        define_schema do
          property :metadata, String, default: { 'key' => 'value' }
        end
      end
    end

    it 'gives each instance its own copy of the default hash' do
      a = model.new
      b = model.new

      a.metadata['injected'] = 'surprise'

      expect(b.metadata).to eq({ 'key' => 'value' }),
                            "Instance b saw a's mutation: b.metadata=#{b.metadata.inspect}. " \
                            'Mutable default is shared across instances.'
    end
  end
end
