# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'get_type_class should not silently fall back to String' do
  # A T::AnyOf[Integer, String] property is a valid, documented EasyTalk type.
  # The schema builder correctly produces anyOf: [{type: integer}, {type: string}].
  # But get_type_class resolves the AnyOf composer object to String (the fallback),
  # which causes the validation adapter to route through apply_string_validations.
  # This applies string-specific validations (length, format, pattern) to a
  # composition type that can also be an Integer.

  let(:model) do
    Class.new do
      include EasyTalk::Model

      def self.name = 'ApiResponse'

      define_schema do
        property :result, T::AnyOf[Integer, String], min_length: 1
      end
    end
  end

  describe 'schema generation' do
    it 'correctly generates an anyOf schema' do
      schema = model.json_schema
      result_schema = schema['properties']['result']

      # The schema is correct — it says anyOf: [integer, string]
      expect(result_schema['anyOf']).to include({ 'type' => 'integer' }, { 'type' => 'string' })
    end
  end

  describe 'validation behavior' do
    it 'should not apply string length validation to a composition type' do
      # The type is T::AnyOf[Integer, String], so get_type_class should
      # return nil (unrecognized composition type), and the validation
      # adapter should skip type-specific validations entirely.
      #
      # Instead, get_type_class returns String, so apply_string_validations
      # runs and adds a length: { minimum: 1 } validator — a string-specific
      # check on a type that can also be an Integer.
      record = model.new(result: '')
      record.valid?
      length_errors = record.errors.full_messages.select { |m| m.include?('too short') }

      expect(length_errors).to be_empty,
        "A T::AnyOf[Integer, String] property should not get string length " \
        "validation applied, but get_type_class resolved the composition " \
        "type to String, routing it through apply_string_validations."
    end
  end
end
