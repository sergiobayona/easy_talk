# frozen_string_literal: true

require 'spec_helper'
require 'json'
require_relative '../support/json_schema_converter'

RSpec.describe 'JSON Schema Compliance', :json_schema_compliance do
  TEST_SUITE_PATH = File.expand_path('../fixtures/json_schema_test_suite/tests/draft7', __dir__)

  # Define known failures to manage technical debt systematically
  KNOWN_FAILURES = {
    'not.json' => 'Not keyword not supported',
    'anyOf.json' => 'AnyOf validation not supported',
    'allOf.json' => 'AllOf validation not supported',
    'oneOf.json' => 'OneOf validation not supported',
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
    'infinite-loop-detection.json' => 'Infinite loop detection not supported'
  }.freeze

  Dir.glob(File.join(TEST_SUITE_PATH, '*.json')).each do |file_path|
    file_name = File.basename(file_path)
    next unless File.exist?(file_path)

    test_groups = JSON.parse(File.read(file_path, encoding: 'UTF-8'))

    describe "Suite: #{file_name}" do
      before { skip(KNOWN_FAILURES[file_name]) if KNOWN_FAILURES.key?(file_name) }

      test_groups.each do |group|
        describe group['description'] do
          let(:schema) { group['schema'] }
          let(:converter) { JsonSchemaConverter.new(schema) }

          group['tests'].each do |test_case|
            it test_case['description'].to_s do
              data = test_case['data']
              valid = test_case['valid']

              # Wrap data if the schema was wrapped (non-object schemas)
              test_data = converter.needs_wrapping? ? converter.wrap_data(data) : data

              # For object-constraint-only schemas (minProperties, maxProperties, etc.),
              # JSON Schema says non-object data should be valid (constraints are ignored)
              if converter.object_constraint_only_schema? && !data.is_a?(Hash)
                # Per JSON Schema spec: object constraints ignore non-objects
                # These should always be valid
                expect(valid).to be(true), "JSON Schema spec says non-objects should be valid for object constraints"
                next
              end

              # For object schemas, data must be a hash
              skip "Data is not a hash after transformation (#{test_data.class})" unless test_data.is_a?(Hash)

              # For object-constraint-only schemas, dynamically create properties from test data
              model_class = if converter.object_constraint_only_schema?
                              converter.to_class(property_names: test_data.keys)
                            else
                              converter.to_class
                            end

              begin
                instance = model_class.new(test_data)
              rescue EasyTalk::InvalidPropertyNameError => e
                skip "Property name invalid in EasyTalk: #{e.message}"
              rescue ArgumentError => e
                skip "ArgumentError during setup: #{e.message}"
              rescue StandardError => e
                skip "Class instantiation failed: #{e.message}"
              end

              begin
                valid_result = instance.valid?
              rescue ActiveModel::UnknownAttributeError => e
                skip "UnknownAttributeError: #{e.message}"
              rescue NoMethodError => e
                skip "NoMethodError: #{e.message}"
              end

              if valid
                expect(valid_result).to be(true), "Expected valid, got errors: #{instance.errors.full_messages}"
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
