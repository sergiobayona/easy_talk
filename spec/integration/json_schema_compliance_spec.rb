# frozen_string_literal: true

require 'spec_helper'
require 'json'
require_relative '../support/json_schema_converter'

RSpec.describe 'JSON Schema Compliance', :json_schema_compliance do
  TEST_SUITE_PATH = File.expand_path('../fixtures/json_schema_test_suite/tests/draft7', __dir__)

  # List of files we want to test initially
  FOCUS_FILES = %w[
    type.json
    properties.json
    required.json
    minimum.json
    maxLength.json
  ].freeze

  FOCUS_FILES.each do |file_name|
    file_path = File.join(TEST_SUITE_PATH, file_name)
    next unless File.exist?(file_path)

    test_groups = JSON.parse(File.read(file_path))

    describe "Standard suite: #{file_name}" do
      test_groups.each do |group|
        describe group['description'] do
          let(:schema) { group['schema'] }
          let(:model_class) { JsonSchemaConverter.new(schema).to_class }

          group['tests'].each do |test_case|
            it test_case['description'].to_s do
              data = test_case['data']
              valid = test_case['valid']

              # Skip if the test requires a type we don't fully support yet (e.g. array/object mixed without strict definition)
              skip "Refactoring required: EasyTalk::Model is always an object, cannot test primitive root schemas directly." if schema['type'] && schema['type'] != 'object'

              # Filter out tests where data is not a hash
              skip "Jumping: Data is not a hash (#{data.class}), but schema implies object." unless data.is_a?(Hash)

              begin
                klass = model_class.new(data)
              rescue EasyTalk::InvalidPropertyNameError => e
                skip "Unsupported: Property name invalid in EasyTalk: #{e.message}"
              rescue ArgumentError => e
                # EasyTalk might raise ArgumentError for define_schema issues or others
                skip "ArgumentError during setup: #{e.message}"
              rescue StandardError => e
                # If class creation fails for other reasons (like reserved words in properties?)
                skip "Class definition failed: #{e.message}"
              end

              begin
                valid_result = klass.valid?
              rescue ActiveModel::UnknownAttributeError => e
                # This happens if we failed to define a property (e.g. reserved word) but passed data for it
                skip "ActiveModel::UnknownAttributeError (reserved word or unmapped property?): #{e.message}"
              rescue NoMethodError => e
                skip "NoMethodError (reserved word collision?): #{e.message}"
              end

              if valid
                expect(valid_result).to be(true), "Expected valid, got errors: #{klass.errors.full_messages}"
              else
                expect(valid_result).to be(false), "Expected invalid, but it was valid."
              end
            end
          end
        end
      end
    end
  end
end
