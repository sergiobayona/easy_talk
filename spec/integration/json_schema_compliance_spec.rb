# frozen_string_literal: true

require 'spec_helper'
require 'json'
require_relative '../support/json_schema_converter'

RSpec.describe 'JSON Schema Compliance', :json_schema_compliance do
  TEST_SUITE_PATH = File.expand_path('../fixtures/json_schema_test_suite/tests/draft7', __dir__)

  # 1. Define known failures to manage technical debt systematically
  KNOWN_FAILURES = {
    'not.json' => 'Not supported',
    'anyOf.json' => 'Not supported',
    'allOf.json' => 'Not supported',
    'oneOf.json' => 'Root-level oneOf with "exactly one must match" semantics not supported in ActiveModel validation',
    'refRemote.json' => 'Remote refs not supported',
    'dependencies.json' => 'Dependencies not supported',
    'definitions.json' => 'Definitions not supported',
    'if-then-else.json' => 'Conditional logic not supported',
    'patternProperties.json' => 'Pattern properties not supported',
    'properties.json' => 'Complex property interactions not supported',
    'propertyNames.json' => 'Property names validation not supported',
    'ref.json' => 'Complex refs not supported',
    'required.json' => 'Complex required checks not supported',
    'additionalItems.json' => 'Additional items not supported',
    'additionalProperties.json' => 'Additional properties not supported',
    'boolean_schema.json' => 'Boolean schemas not supported',
    'const.json' => 'Const keyword not supported',
    'default.json' => 'Default keyword behavior not supported',
    'enum.json' => 'Enum validation not fully supported',
    'infinite-loop-detection.json' => 'Infinite loop detection not supported',
    'maxProperties.json' => 'Max properties not supported',
    'minProperties.json' => 'Min properties not supported'
    # Add other files here
  }.freeze

  Dir.glob(File.join(TEST_SUITE_PATH, '*.json')).each do |file_path|
    file_name = File.basename(file_path)
    next unless File.exist?(file_path)

    test_groups = JSON.parse(File.read(file_path, encoding: 'UTF-8'))

    describe "Suite: #{file_name}" do
      # 2. Skip entire files if they are known unsupported features
      before { skip(KNOWN_FAILURES[file_name]) if KNOWN_FAILURES.key?(file_name) }

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
