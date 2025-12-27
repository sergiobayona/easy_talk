# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::ErrorFormatter do
  let(:address_class) do
    Class.new do
      include EasyTalk::Model

      def self.name = 'Address'

      define_schema do
        property :street, String, min_length: 5
        property :city, String, min_length: 3
      end
    end
  end

  let(:test_class) do
    addr_class = address_class
    Class.new do
      include EasyTalk::Model

      define_singleton_method(:name) { 'ErrorFormatterTest' }

      define_schema do
        property :name, String, min_length: 2
        property :email, String, format: 'email'
        property :address, addr_class
      end
    end
  end

  describe '.format' do
    let(:instance) { test_class.new(name: '', email: 'invalid') }

    before { instance.valid? }

    it 'formats errors using the specified format' do
      result = described_class.format(instance.errors, format: :flat)
      expect(result).to be_an(Array)
    end

    it 'uses default format from configuration' do
      original = EasyTalk.configuration.default_error_format
      EasyTalk.configuration.default_error_format = :flat

      result = described_class.format(instance.errors)
      expect(result).to be_an(Array)

      EasyTalk.configuration.default_error_format = original
    end

    it 'raises ArgumentError for unknown format' do
      expect do
        described_class.format(instance.errors, format: :unknown)
      end.to raise_error(ArgumentError, /Unknown error format: unknown/)
    end

    it 'passes options to the formatter' do
      result = described_class.format(instance.errors, format: :rfc7807, title: 'Custom Title')
      expect(result['title']).to eq('Custom Title')
    end
  end

  describe 'InstanceMethods' do
    let(:instance) { test_class.new(name: '', email: 'invalid') }

    before { instance.valid? }

    describe '#validation_errors' do
      it 'returns formatted errors using default format' do
        result = instance.validation_errors
        expect(result).to be_an(Array)
      end

      it 'accepts format option' do
        result = instance.validation_errors(format: :rfc7807)
        expect(result).to be_a(Hash)
        expect(result['type']).to be_a(String)
      end

      it 'passes additional options' do
        result = instance.validation_errors(format: :rfc7807, title: 'Custom')
        expect(result['title']).to eq('Custom')
      end
    end

    describe '#validation_errors_flat' do
      it 'returns flat format' do
        result = instance.validation_errors_flat
        expect(result).to be_an(Array)
        expect(result.first).to have_key('field')
      end
    end

    describe '#validation_errors_json_pointer' do
      it 'returns JSON Pointer format' do
        result = instance.validation_errors_json_pointer
        expect(result).to be_an(Array)
        expect(result.first).to have_key('pointer')
      end
    end

    describe '#validation_errors_rfc7807' do
      it 'returns RFC 7807 format' do
        result = instance.validation_errors_rfc7807
        expect(result).to be_a(Hash)
        expect(result).to have_key('type')
        expect(result).to have_key('title')
        expect(result).to have_key('status')
        expect(result).to have_key('errors')
      end

      it 'accepts options' do
        result = instance.validation_errors_rfc7807(title: 'User Error', status: 400)
        expect(result['title']).to eq('User Error')
        expect(result['status']).to eq(400)
      end
    end

    describe '#validation_errors_jsonapi' do
      it 'returns JSON:API format' do
        result = instance.validation_errors_jsonapi
        expect(result).to be_a(Hash)
        expect(result).to have_key('errors')
        expect(result['errors'].first).to have_key('source')
        expect(result['errors'].first).to have_key('status')
      end

      it 'accepts options' do
        result = instance.validation_errors_jsonapi(title: 'Validation Error')
        expect(result['errors'].first['title']).to eq('Validation Error')
      end
    end
  end

  describe 'nested model errors' do
    # Use valid street but invalid city to trigger nested error propagation
    # (when all fields are blank, parent reports "can't be blank" instead)
    let(:instance) { test_class.new(name: 'John', address: { street: 'Main Street', city: 'AB' }) }

    before { instance.valid? }

    it 'formats nested errors with flat paths' do
      result = instance.validation_errors_flat

      nested_errors = result.select { |e| e['field'].to_s.include?('.') }
      expect(nested_errors).not_to be_empty

      city_error = result.find { |e| e['field'] == 'address.city' }
      expect(city_error).to be_present
    end

    it 'formats nested errors with JSON Pointer paths' do
      result = instance.validation_errors_json_pointer

      nested_errors = result.select { |e| e['pointer'].include?('/address/') }
      expect(nested_errors).not_to be_empty

      city_error = result.find { |e| e['pointer'] == '/properties/address/properties/city' }
      expect(city_error).to be_present
    end

    it 'formats nested errors with JSON:API paths' do
      result = instance.validation_errors_jsonapi

      city_error = result['errors'].find { |e| e['source']['pointer'].include?('address') }
      expect(city_error).to be_present
      expect(city_error['source']['pointer']).to eq('/data/attributes/address/city')
    end
  end

  describe 'configuration' do
    describe 'default_error_format' do
      it 'defaults to :flat' do
        expect(EasyTalk.configuration.default_error_format).to eq(:flat)
      end

      it 'can be changed' do
        original = EasyTalk.configuration.default_error_format
        EasyTalk.configuration.default_error_format = :rfc7807
        expect(EasyTalk.configuration.default_error_format).to eq(:rfc7807)
        EasyTalk.configuration.default_error_format = original
      end
    end

    describe 'error_type_base_uri' do
      it 'defaults to "about:blank"' do
        expect(EasyTalk.configuration.error_type_base_uri).to eq('about:blank')
      end
    end

    describe 'include_error_codes' do
      it 'defaults to true' do
        expect(EasyTalk.configuration.include_error_codes).to be true
      end
    end
  end
end
