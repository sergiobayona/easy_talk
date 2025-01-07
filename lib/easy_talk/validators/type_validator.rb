module EasyTalk
  module Validators
    class TypeValidator < ActiveModel::Validator
      def validate(record)
        schema = record.class.json_schema
        check_types(record, record, schema, "")
      end

      private

      ##
      # Recursively checks types based on the schema.
      # @param record [Object] the top-level record (for adding errors).
      # @param data   [Object, Hash] the current data slice (the model or a nested Hash).
      # @param schema [Hash] the relevant slice of the JSON schema.
      # @param path   [String] dotted path for error messages (e.g. `"email.verified"`).
      #
      def check_types(record, data, schema, path)
        return unless schema.is_a?(Hash)

        # Each property in the schema
        (schema["properties"] || {}).each do |prop, prop_schema|
          property_path = path.empty? ? prop : "#{path}.#{prop}"
          value         = get_value(data, prop)

          # If there's a declared "type" at this level, confirm it matches
          if prop_schema["type"]
            # Skip further type checks if it's an object or array (handled below)
            unless %w[object array].include?(prop_schema["type"])
              unless is_correct_type?(value, prop_schema["type"])
                record.errors.add(property_path, "is not a valid #{prop_schema["type"]}")
                # If type is wrong, no need to recurse further for this property
                next
              end
            end
          end

          # Handle nested structures
          case prop_schema["type"]
          when "object"
            validate_nested_object(record, value, prop_schema, property_path)
          when "array"
            validate_nested_array(record, value, prop_schema, property_path)
          end
        end
      end

      ##
      # If the property is a nested "object," it can be:
      # 1) A Hash (for inline block-style definitions),
      # 2) Another EasyTalk::Model instance (referenced class).
      #
      def validate_nested_object(record, value, schema, path)
        # If it’s an EasyTalk::Model, we can just rely on the sub-model’s `.valid?`
        if value_looks_like_easytalk_model?(value)
          unless value.valid?
            copy_nested_errors(record, value, path)
          end
        elsif value.is_a?(Hash)
          # Recurse into its properties
          check_types(record, value, schema, path)
        end
        # If it's neither a Hash nor a model, you could add an error or skip.
      end

      ##
      # If the property is a nested "array", each item might be an object or a primitive.
      #
      def validate_nested_array(record, value, schema, path)
        return unless value.is_a?(Array)

        item_schema = schema["items"] || {}
        value.each_with_index do |item_value, idx|
          item_path = "#{path}[#{idx}]"

          # If the item’s declared type is "object", check if it’s a model or a Hash
          if item_schema["type"] == "object"
            validate_nested_object(record, item_value, item_schema, item_path)
          elsif item_schema["type"] == "array"
            # Arrays of arrays? Recursively handle them if needed:
            validate_nested_array(record, item_value, item_schema, item_path)
          else
            # Otherwise, do a direct type check if declared
            if item_schema["type"] && !%w[object array].include?(item_schema["type"])
              unless is_correct_type?(item_value, item_schema["type"])
                record.errors.add(item_path, "is not a valid #{item_schema["type"]}")
              end
            end
          end
        end
      end

      ##
      # Utility to decide if `value` is an EasyTalk model.
      #
      def value_looks_like_easytalk_model?(value)
        value.respond_to?(:class) &&
          value.class.included_modules.include?(EasyTalk::Model)
      end

      ##
      # Merge nested errors from a sub-model into the parent record’s errors.
      #
      def copy_nested_errors(parent_record, child_record, property_path)
        child_record.errors.each do |attr, msg|
          parent_record.errors.add("#{property_path}.#{attr}", msg)
        end
      end

      ##
      # Retrieve a property’s value from `data`, which might be:
      # - the top-level model (call `data.send(prop)`), or
      # - a Hash (do `data[prop]`).
      #
      def get_value(data, prop)
        if data.is_a?(Hash)
          data[prop] || data[prop.to_sym]
        elsif data.respond_to?(prop)
          data.send(prop)
        else
          nil
        end
      end

      ##
      # Returns true if `value` matches the given JSON schema `type`:
      #
      #  - "string"   => `value.is_a?(String)`
      #  - "integer"  => `value.is_a?(Integer)`
      #  - "number"   => `value.is_a?(Numeric)`
      #  - "boolean"  => `[true, false].include?(value)`
      #  - "null"     => `value.nil?`
      #  - otherwise  => do nothing special (e.g. "object" or "array" are handled separately)
      #
      def is_correct_type?(value, schema_type)
        case schema_type
        when "string"   then value.is_a?(String)
        when "integer"  then value.is_a?(Integer)
        when "number"   then value.is_a?(Numeric)
        when "boolean"  then (value == true || value == false)
        when "null"     then value.nil?
        else
          # "object" / "array" handled separately, or unrecognized type => pass for now
          true
        end
      end
    end
  end
end
