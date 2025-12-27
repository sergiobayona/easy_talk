# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::ErrorFormatter::Flat do
  let(:test_class) do
    Class.new do
      include EasyTalk::Model

      def self.name = 'FlatFormatterTest'

      define_schema do
        property :name, String, min_length: 2
        property :email, String, format: 'email'
        property :age, Integer, minimum: 0
      end
    end
  end

  describe '#format' do
    context 'with simple errors' do
      it 'formats errors as flat array with codes' do
        instance = test_class.new(name: '', email: 'invalid', age: -1)
        instance.valid?

        formatter = described_class.new(instance.errors)
        result = formatter.format

        expect(result).to be_an(Array)
        expect(result.length).to be >= 3 # May include presence errors

        name_error = result.find { |e| e['field'] == 'name' }
        expect(name_error).to include(
          'field' => 'name',
          'message' => a_kind_of(String)
        )
        expect(name_error['code']).to be_a(String)
      end
    end

    context 'without error codes' do
      before do
        EasyTalk.configuration.include_error_codes = false
      end

      after do
        EasyTalk.configuration.include_error_codes = true
      end

      it 'omits code when include_codes is false' do
        instance = test_class.new(name: '')
        instance.valid?

        formatter = described_class.new(instance.errors)
        result = formatter.format

        expect(result.first).not_to have_key('code')
      end
    end

    context 'with include_codes option override' do
      it 'respects per-call include_codes option' do
        instance = test_class.new(name: '')
        instance.valid?

        formatter = described_class.new(instance.errors, include_codes: false)
        result = formatter.format

        expect(result.first).not_to have_key('code')
      end
    end
  end
end
