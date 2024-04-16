# frozen_string_literal: true

module EasyTalk
  module Tools
    module FunctionBuilder
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
