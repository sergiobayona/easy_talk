# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::Tools::FunctionBuilder do
  let(:model) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'MyModel'
      end

      define_schema do
        property :name, String
        property :age, Integer
      end
    end
  end

  describe '.build' do
    let(:expected_json) do
      {
        type: 'function',
        function: {
          name: 'MyModel',
          description: 'Correctly extracted `MyModel` with all the required parameters and correct types.',
          parameters: {
            type: 'object',
            properties: {
              name: { type: 'string' },
              age: { type: 'integer' }
            },
            required: %w[name age]
          }
        }
      }
    end

    it 'returns a hash with the function type and function details' do
      expect(described_class.new(model)).to include_json(expected_json)
    end
  end

  context 'when model has non-string instructions' do
    let(:model_with_bad_instructions) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'BadModel'
        end

        def self.instructions
          123 # Not a string
        end

        define_schema do
          property :name, String
        end
      end
    end

    it 'raises InvalidInstructionsError' do
      expect do
        described_class.new(model_with_bad_instructions)
      end.to raise_error(EasyTalk::InvalidInstructionsError, 'The instructions must be a string')
    end
  end
end
