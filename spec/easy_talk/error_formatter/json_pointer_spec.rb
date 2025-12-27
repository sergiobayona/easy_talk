# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::ErrorFormatter::JsonPointer do
  let(:test_class) do
    Class.new do
      include EasyTalk::Model

      def self.name = 'JsonPointerFormatterTest'

      define_schema do
        property :name, String, min_length: 2
        property :age, Integer, minimum: 0
      end
    end
  end

  describe '#format' do
    it 'formats errors with JSON Pointer paths' do
      instance = test_class.new(name: '', age: -1)
      instance.valid?

      formatter = described_class.new(instance.errors)
      result = formatter.format

      expect(result).to be_an(Array)

      name_error = result.find { |e| e['pointer'] == '/properties/name' }
      expect(name_error).to include(
        'pointer' => '/properties/name',
        'message' => a_kind_of(String)
      )
      expect(name_error['code']).to be_a(String)

      age_error = result.find { |e| e['pointer'] == '/properties/age' }
      expect(age_error).to include(
        'pointer' => '/properties/age',
        'message' => a_kind_of(String)
      )
    end

    context 'without error codes' do
      it 'omits code when include_codes is false' do
        instance = test_class.new(name: '')
        instance.valid?

        formatter = described_class.new(instance.errors, include_codes: false)
        result = formatter.format

        expect(result.first).not_to have_key('code')
      end
    end
  end
end
