# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::ErrorFormatter::Rfc7807 do
  let(:test_class) do
    Class.new do
      include EasyTalk::Model

      def self.name = 'Rfc7807FormatterTest'

      define_schema do
        property :name, String, min_length: 2
        property :age, Integer, minimum: 0
      end
    end
  end

  describe '#format' do
    it 'formats errors as RFC 7807 Problem Details' do
      instance = test_class.new(name: '', age: -1)
      instance.valid?

      formatter = described_class.new(instance.errors)
      result = formatter.format

      expect(result).to be_a(Hash)
      expect(result['type']).to eq('validation-error')
      expect(result['title']).to eq('Validation Failed')
      expect(result['status']).to eq(422)
      expect(result['detail']).to eq('The request contains invalid parameters')
      expect(result['errors']).to be_an(Array)
      expect(result['errors'].length).to be >= 2 # May include presence errors
    end

    it 'includes pointer and detail in error objects' do
      instance = test_class.new(name: '')
      instance.valid?

      formatter = described_class.new(instance.errors)
      result = formatter.format

      error = result['errors'].first
      expect(error['pointer']).to eq('/properties/name')
      expect(error['detail']).to be_a(String)
      expect(error['code']).to be_a(String)
    end

    context 'with custom options' do
      it 'uses custom title' do
        instance = test_class.new(name: '')
        instance.valid?

        formatter = described_class.new(instance.errors, title: 'Custom Validation Error')
        result = formatter.format

        expect(result['title']).to eq('Custom Validation Error')
      end

      it 'uses custom status' do
        instance = test_class.new(name: '')
        instance.valid?

        formatter = described_class.new(instance.errors, status: 400)
        result = formatter.format

        expect(result['status']).to eq(400)
      end

      it 'uses custom detail' do
        instance = test_class.new(name: '')
        instance.valid?

        formatter = described_class.new(instance.errors, detail: 'Custom detail message')
        result = formatter.format

        expect(result['detail']).to eq('Custom detail message')
      end

      it 'uses custom type_base_uri' do
        instance = test_class.new(name: '')
        instance.valid?

        formatter = described_class.new(instance.errors, type_base_uri: 'https://api.example.com/errors')
        result = formatter.format

        expect(result['type']).to eq('https://api.example.com/errors/validation-error')
      end

      it 'uses custom type' do
        instance = test_class.new(name: '')
        instance.valid?

        formatter = described_class.new(instance.errors, type_base_uri: 'https://api.example.com', type: 'invalid-input')
        result = formatter.format

        expect(result['type']).to eq('https://api.example.com/invalid-input')
      end
    end

    context 'with about:blank base URI' do
      it 'uses type directly without base URI' do
        instance = test_class.new(name: '')
        instance.valid?

        formatter = described_class.new(instance.errors, type_base_uri: 'about:blank')
        result = formatter.format

        expect(result['type']).to eq('validation-error')
      end
    end
  end
end
