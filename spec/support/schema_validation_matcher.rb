# frozen_string_literal: true

require 'json_schemer'

module EasyTalk
  module RSpec
    # Custom RSpec matcher that validates data against an EasyTalk model's JSON Schema
    # using json_schemer, then compares with ActiveModel validation results.
    #
    # @example Basic usage - validate data matches schema
    #   expect(User).to validate_schema_for(name: "John", email: "john@example.com")
    #
    # @example Expect schema validation to fail
    #   expect(User).not_to validate_schema_for(name: "", email: "invalid")
    #
    # @example Check that ActiveModel and JSON Schema validations agree
    #   expect(User).to have_matching_validations_for(name: "John", email: "john@example.com")
    #
    class SchemaValidationMatcher
      def initialize(data)
        @data = data
        @schema_errors = []
        @model_instance = nil
      end

      def matches?(model_class)
        @model_class = model_class
        @schema = model_class.json_schema
        @schemer = JSONSchemer.schema(@schema)

        # Validate against JSON Schema
        normalized_data = normalize_data(@data)
        @schema_errors = @schemer.validate(normalized_data).to_a

        @schema_errors.empty?
      end

      def failure_message
        error_details = @schema_errors.map do |error|
          "  - #{error['data_pointer']}: #{error['type']} (#{error['error']})"
        end.join("\n")

        "expected #{@model_class} schema to validate data:\n#{@data.inspect}\n\n" \
          "but got schema errors:\n#{error_details}"
      end

      def failure_message_when_negated
        "expected #{@model_class} schema to reject data:\n#{@data.inspect}\n\n" \
          'but it was valid'
      end

      private

      def normalize_data(data)
        case data
        when Hash
          data.transform_keys(&:to_s).transform_values { |v| normalize_data(v) }
        when Array
          data.map { |v| normalize_data(v) }
        else
          data
        end
      end
    end

    # Matcher that checks if ActiveModel validations and JSON Schema validations agree
    class MatchingValidationsMatcher
      ValidationResult = Struct.new(:valid, :errors, keyword_init: true)

      def initialize(data)
        @data = data
        @schema_result = nil
        @active_model_result = nil
        @mismatches = []
      end

      def matches?(model_class)
        @model_class = model_class

        @schema_result = validate_with_schema(model_class)
        @active_model_result = validate_with_active_model(model_class)

        analyze_mismatches

        @schema_result.valid == @active_model_result.valid && @mismatches.empty?
      end

      def failure_message
        build_comparison_message('to have matching validations')
      end

      def failure_message_when_negated
        build_comparison_message('to have mismatching validations')
      end

      private

      def validate_with_schema(model_class)
        schema = model_class.json_schema
        schemer = JSONSchemer.schema(schema)
        errors = schemer.validate(normalize_data(@data)).to_a

        ValidationResult.new(
          valid: errors.empty?,
          errors: errors.map { |e| format_schema_error(e) }
        )
      end

      def validate_with_active_model(model_class)
        instance = model_class.new(@data)
        valid = instance.valid?

        ValidationResult.new(
          valid: valid,
          errors: instance.errors.map { |e| { attribute: e.attribute.to_s, message: e.message, type: e.type } }
        )
      end

      def format_schema_error(error)
        {
          pointer: error['data_pointer'],
          type: error['type'],
          details: error['error']
        }
      end

      def analyze_mismatches
        @mismatches = []

        if @schema_result.valid != @active_model_result.valid
          @mismatches << {
            type: :validity_mismatch,
            schema_valid: @schema_result.valid,
            active_model_valid: @active_model_result.valid
          }
        end

        # Check for errors that exist in one but not the other
        analyze_error_coverage
      end

      def analyze_error_coverage
        schema_error_paths = @schema_result.errors.filter_map { |e| e[:pointer] }
        active_model_attrs = @active_model_result.errors.map { |e| e[:attribute] }

        # Schema errors not covered by ActiveModel
        schema_error_paths.each do |path|
          attr = path_to_attribute(path)
          next if active_model_attrs.any? { |a| a == attr || a.start_with?("#{attr}.") || a.start_with?("#{attr}[") }

          @mismatches << { type: :schema_only, path: path, attribute: attr }
        end
      end

      def path_to_attribute(pointer)
        pointer.gsub(%r{^/}, '').tr('/', '.')
      end

      def build_comparison_message(expectation)
        msg = ["expected #{@model_class} #{expectation} for data:", @data.inspect, '']

        msg << 'JSON Schema validation:'
        msg << "  Valid: #{@schema_result.valid}"
        if @schema_result.errors.any?
          msg << '  Errors:'
          @schema_result.errors.each { |e| msg << "    - #{e[:pointer]}: #{e[:type]}" }
        end

        msg << ''
        msg << 'ActiveModel validation:'
        msg << "  Valid: #{@active_model_result.valid}"
        if @active_model_result.errors.any?
          msg << '  Errors:'
          @active_model_result.errors.each { |e| msg << "    - #{e[:attribute]}: #{e[:message]}" }
        end

        if @mismatches.any?
          msg << ''
          msg << 'Mismatches detected:'
          @mismatches.each do |m|
            case m[:type]
            when :validity_mismatch
              msg << "  - Validity differs: Schema=#{m[:schema_valid]}, ActiveModel=#{m[:active_model_valid]}"
            when :schema_only
              msg << "  - Schema error not caught by ActiveModel: #{m[:path]}"
            when :active_model_only
              msg << "  - ActiveModel error not in schema: #{m[:attribute]}"
            end
          end
        end

        msg.join("\n")
      end

      def normalize_data(data)
        case data
        when Hash
          data.transform_keys(&:to_s).transform_values { |v| normalize_data(v) }
        when Array
          data.map { |v| normalize_data(v) }
        else
          data
        end
      end
    end

    # Detailed schema validation result for debugging and assertions
    class SchemaValidationResult
      attr_reader :model_class, :data, :schema, :schema_errors, :model_instance

      def initialize(model_class, data)
        @model_class = model_class
        @data = data
        @schema = model_class.json_schema
        @schemer = JSONSchemer.schema(@schema)

        perform_validation
      end

      def schema_valid?
        @schema_errors.empty?
      end

      def active_model_valid?
        @model_instance.valid?
      end

      def validations_match?
        schema_valid? == active_model_valid?
      end

      def schema_error_pointers
        @schema_errors.map { |e| e['data_pointer'] }
      end

      def schema_error_types
        @schema_errors.map { |e| e['type'] }
      end

      def active_model_error_attributes
        @model_instance.errors.map(&:attribute)
      end

      def active_model_error_messages
        @model_instance.errors.full_messages
      end

      def formatted_errors
        @model_instance.validation_errors_flat
      end

      def to_h
        {
          schema_valid: schema_valid?,
          schema_errors: @schema_errors.map { |e| { pointer: e['data_pointer'], type: e['type'] } },
          active_model_valid: active_model_valid?,
          active_model_errors: @model_instance.errors.to_a.map { |e| { attribute: e.attribute, message: e.message } },
          formatted_errors: formatted_errors,
          validations_match: validations_match?
        }
      end

      private

      def perform_validation
        normalized = normalize_data(@data)
        @schema_errors = @schemer.validate(normalized).to_a
        @model_instance = @model_class.new(@data)
        @model_instance.valid?
      end

      def normalize_data(data)
        case data
        when Hash
          data.transform_keys(&:to_s).transform_values { |v| normalize_data(v) }
        when Array
          data.map { |v| normalize_data(v) }
        else
          data
        end
      end
    end
  end
end

# RSpec matcher DSL methods
module EasyTalk
  module RSpec
    module Matchers
      # Validates that data passes JSON Schema validation for a model
      #
      # @example
      #   expect(User).to validate_schema_for(name: "John", age: 30)
      #   expect(User).not_to validate_schema_for(name: "", age: -1)
      #
      def validate_schema_for(data)
        SchemaValidationMatcher.new(data)
      end

      # Validates that ActiveModel and JSON Schema validations produce the same result
      #
      # @example
      #   expect(User).to have_matching_validations_for(name: "John", age: 30)
      #
      def have_matching_validations_for(data)
        MatchingValidationsMatcher.new(data)
      end

      # Helper to get detailed validation results for debugging
      #
      # @example
      #   result = schema_validation_result(User, { name: "", age: -1 })
      #   expect(result.schema_valid?).to be false
      #   expect(result.schema_error_pointers).to include("/name")
      #
      def schema_validation_result(model_class, data)
        SchemaValidationResult.new(model_class, data)
      end
    end
  end
end

RSpec.configure do |config|
  config.include EasyTalk::RSpec::Matchers
end
