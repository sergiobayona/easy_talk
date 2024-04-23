# frozen_string_literal: true

module EasyTalk
  module Tools
    # FunctionBuilder is a module that builds a hash with the function type and function details.
    # The return value is typically passed as argument to LLM function calling APIs.
    module FunctionBuilder
      # Creates a new function object based on the given model.
      #
      # @param [Model] model The EasyTalk model containing the function details.
      # @return [Hash] The function object.
      def self.new(model)
        {
          type: 'function',
          function: {
            name: model.function_name,
            description: generate_description(model),
            parameters: model.json_schema
          }
        }
      end

      def self.generate_description(model)
        "Correctly extracted `#{model.name}` with all the required parameters with correct types"
      end
    end
  end
end
