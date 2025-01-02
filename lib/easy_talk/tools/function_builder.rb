# frozen_string_literal: true

module EasyTalk
  module Tools
    # FunctionBuilder is a module that builds a hash with the function type and function details.
    # The return value is typically passed as argument to LLM function calling APIs.
    module FunctionBuilder
      class << self
        # Creates a new function object based on the given model.
        #
        # @param [Model] model The EasyTalk model containing the function details.
        # @return [Hash] The function object.
        def new(model)
          {
            type: 'function',
            function: {
              name: generate_function_name(model),
              description: generate_function_description(model),
              parameters: model.json_schema
            }
          }
        end

        def generate_function_name(model)
          model.schema.fetch(:title, model.name)
        end

        def generate_function_description(model)
          if model.respond_to?(:instructions)
            raise Instructor::Error, 'The instructions must be a string' unless model.instructions.is_a?(String)

            model.instructions
          else
            "Correctly extracted `#{model.name}` with all the required parameters and correct types."
          end
        end
      end
    end
  end
end
