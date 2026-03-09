# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Optional array properties and nil acceptance' do
  context 'when array property is optional' do
    let(:klass) do
      Class.new do
        include EasyTalk::Model

        def self.name = 'OptionalArrayModel'

        define_schema do
          property :tags, T::Array[String], optional: true
        end
      end
    end

    it 'accepts nil (property omitted)' do
      obj = klass.new
      expect(obj).to be_valid
    end

    it 'accepts an empty array' do
      obj = klass.new(tags: [])
      expect(obj).to be_valid
    end

    it 'accepts a populated array' do
      obj = klass.new(tags: %w[ruby python])
      expect(obj).to be_valid
    end

    it 'does not include property in required' do
      expect(klass.json_schema['required']).to be_nil
    end
  end

  context 'when array property is required (default)' do
    let(:klass) do
      Class.new do
        include EasyTalk::Model

        def self.name = 'RequiredArrayModel'

        define_schema do
          property :tags, T::Array[String]
        end
      end
    end

    it 'rejects nil' do
      obj = klass.new
      expect(obj).not_to be_valid
      expect(obj.errors[:tags]).to include("can't be blank")
    end

    it 'accepts an empty array' do
      obj = klass.new(tags: [])
      expect(obj).to be_valid
    end

    it 'accepts a populated array' do
      obj = klass.new(tags: %w[ruby python])
      expect(obj).to be_valid
    end
  end
end
