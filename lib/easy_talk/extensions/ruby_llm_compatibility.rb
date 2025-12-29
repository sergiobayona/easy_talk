# frozen_string_literal: true

module EasyTalk
  module Extensions
    # Class methods for RubyLLM compatibility.
    # These are added to the model class via `extend`.
    module RubyLLMCompatibility
      # Returns a Hash representing the schema in a format compatible with RubyLLM.
      # RubyLLM expects an object that responds to #to_json_schema and returns
      # a hash with :name, :description, and :schema keys.
      #
      # @return [Hash] The RubyLLM-compatible schema representation
      def to_json_schema
        {
          name: name,
          description: schema_definition.schema[:description] || "Schema for #{name}",
          schema: json_schema
        }
      end
    end

    # Instance methods for RubyLLM tool compatibility.
    # These are added to model instances via `include`.
    #
    # RubyLLM's `with_tool` method instantiates the tool class and expects:
    # - `name`: returns a normalized identifier string
    # - `description`: returns the tool description
    # - `params_schema`: returns the JSON schema for tool parameters
    # - `provider_params`: returns provider-specific parameters
    # - `call(args)`: executes the tool (which delegates to `execute`)
    #
    # RubyLLM's `with_schema` method expects:
    # - `to_json_schema`: returns a hash with :name, :description, and :schema keys
    module RubyLLMToolInstanceMethods
      # Returns a normalized name identifier for the tool.
      # Converts the class name to a snake_case format compatible with RubyLLM.
      #
      # @return [String] The normalized tool name
      def name
        klass_name = self.class.name
        return 'unnamed_tool' if klass_name.nil?

        normalized = klass_name.to_s.dup.force_encoding('UTF-8')
        normalized = normalized.unicode_normalize(:nfkd) if normalized.respond_to?(:unicode_normalize)
        normalized.encode('ASCII', replace: '')
                  .gsub(/[^a-zA-Z0-9_-]/, '-')
                  .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
                  .gsub(/([a-z\d])([A-Z])/, '\1_\2')
                  .downcase
                  .delete_suffix('_tool')
      end

      # Returns the tool description from the schema.
      #
      # @return [String] The tool description
      def description
        schema_def = self.class.schema_definition
        schema_def.schema[:description] || "Tool: #{self.class.name}"
      end

      # Returns the JSON schema for the tool parameters.
      #
      # @return [Hash] The JSON schema for parameters
      def params_schema
        self.class.json_schema
      end

      # Returns provider-specific parameters for the tool.
      #
      # @return [Hash] Provider-specific parameters (empty by default)
      def provider_params
        {}
      end

      # Returns a Hash representing the schema in a format compatible with RubyLLM.
      # Delegates to the class method.
      #
      # @return [Hash] The RubyLLM-compatible schema representation
      def to_json_schema
        self.class.to_json_schema
      end

      # Executes the tool with the given arguments.
      # Passes args as keyword arguments to `execute`, matching RubyLLM's Tool behavior.
      #
      # @param args [Hash] The arguments passed by the LLM
      # @return [Object] The result of the tool execution
      def call(args = {})
        execute(**args.transform_keys(&:to_sym))
      end
    end
  end
end
