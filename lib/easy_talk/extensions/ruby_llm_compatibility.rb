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

    # Overrides for classes that inherit from RubyLLM::Tool.
    # Only overrides schema-related methods, allowing all other RubyLLM::Tool
    # functionality (halt, call, etc.) to work normally.
    #
    # Usage:
    #   class WeatherTool < RubyLLM::Tool
    #     include EasyTalk::Model
    #
    #     define_schema do
    #       description 'Gets current weather'
    #       property :latitude, String
    #       property :longitude, String
    #     end
    #
    #     def execute(latitude:, longitude:)
    #       # Can use halt() since we inherit from RubyLLM::Tool
    #       halt "Weather at #{latitude}, #{longitude}"
    #     end
    #   end
    module RubyLLMToolOverrides
      # Override to use EasyTalk's schema description.
      #
      # @return [String] The tool description from EasyTalk schema
      def description
        schema_def = self.class.schema_definition
        schema_def.schema[:description] || "Tool: #{self.class.name}"
      end

      # Override to use EasyTalk's JSON schema for parameters.
      #
      # @return [Hash] The JSON schema for parameters
      def params_schema
        self.class.json_schema
      end
    end
  end
end
