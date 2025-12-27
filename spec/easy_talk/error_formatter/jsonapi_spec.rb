# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::ErrorFormatter::Jsonapi do
  let(:test_class) do
    Class.new do
      include EasyTalk::Model

      def self.name = 'JsonapiFormatterTest'

      define_schema do
        property :name, String, min_length: 2
        property :age, Integer, minimum: 0
      end
    end
  end

  describe '#format' do
    it 'formats errors according to JSON:API spec' do
      instance = test_class.new(name: '', age: -1)
      instance.valid?

      formatter = described_class.new(instance.errors)
      result = formatter.format

      expect(result).to be_a(Hash)
      expect(result['errors']).to be_an(Array)
      expect(result['errors'].length).to be >= 2 # May include presence errors
    end

    it 'includes required JSON:API error fields' do
      instance = test_class.new(name: '')
      instance.valid?

      formatter = described_class.new(instance.errors)
      result = formatter.format

      error = result['errors'].first
      expect(error['status']).to eq('422')
      expect(error['source']).to be_a(Hash)
      expect(error['source']['pointer']).to eq('/data/attributes/name')
      expect(error['title']).to eq('Invalid Attribute')
      expect(error['detail']).to be_a(String)
      expect(error['code']).to be_a(String)
    end

    it 'uses full_message for detail' do
      instance = test_class.new(name: '')
      instance.valid?

      formatter = described_class.new(instance.errors)
      result = formatter.format

      error = result['errors'].first
      # Full message includes attribute name
      expect(error['detail']).to match(/name/i)
    end

    context 'with custom options' do
      it 'uses custom status' do
        instance = test_class.new(name: '')
        instance.valid?

        formatter = described_class.new(instance.errors, status: 400)
        result = formatter.format

        expect(result['errors'].first['status']).to eq('400')
      end

      it 'uses custom title' do
        instance = test_class.new(name: '')
        instance.valid?

        formatter = described_class.new(instance.errors, title: 'Validation Error')
        result = formatter.format

        expect(result['errors'].first['title']).to eq('Validation Error')
      end

      it 'uses custom source prefix' do
        instance = test_class.new(name: '')
        instance.valid?

        formatter = described_class.new(instance.errors, source_prefix: '/data')
        result = formatter.format

        expect(result['errors'].first['source']['pointer']).to eq('/data/name')
      end
    end

    context 'without error codes' do
      it 'omits code when include_codes is false' do
        instance = test_class.new(name: '')
        instance.valid?

        formatter = described_class.new(instance.errors, include_codes: false)
        result = formatter.format

        expect(result['errors'].first).not_to have_key('code')
      end
    end
  end
end
