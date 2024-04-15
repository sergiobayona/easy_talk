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
    it 'returns a hash with the function type and function details' do
      expect(described_class.new(model)).to include_json(
        type: 'function',
        function: {
          name: 'Mymodel',
          description: 'Correctly extracted `MyModel` with all the required parameters with correct types',
          parameters: {
            type: 'object',
            properties: {
              name: { type: 'string' },
              age: { type: 'integer' }
            },
            required: %w[name age]
          }
        }
      )
    end
  end
end
