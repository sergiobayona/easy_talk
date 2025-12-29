# frozen_string_literal: true

require 'spec_helper'
require 'easy_talk/extensions/ruby_llm_compatibility'

RSpec.describe EasyTalk::Extensions::RubyLLMCompatibility do
  let(:model_class) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'TestModel'
      end

      define_schema do
        description 'A test model'
        property :name, String
      end
    end
  end

  describe '.to_json_schema' do
    subject(:json_schema) { model_class.to_json_schema }

    it 'returns a hash with name, description, and schema' do
      expect(json_schema).to include(
        name: 'TestModel',
        description: 'A test model'
      )
      expect(json_schema[:schema]).to be_a(Hash)
      expect(json_schema[:schema]['properties']).to have_key('name')
    end

    it 'matches RubyLLM expected format' do
      expect(json_schema.keys).to contain_exactly(:name, :description, :schema)
    end
  end
end

RSpec.describe EasyTalk::Extensions::RubyLLMToolOverrides do
  # Minimal mock of RubyLLM::Tool for testing without requiring the gem
  before do
    stub_const('RubyLLM::Tool', Class.new)
  end

  let(:tool_class) do
    Class.new(RubyLLM::Tool) do
      include EasyTalk::Model

      def self.name
        'WeatherTool'
      end

      define_schema do
        description 'Gets current weather for a location'
        property :latitude, String, description: 'Latitude'
        property :longitude, String, description: 'Longitude'
      end
    end
  end

  let(:tool_instance) { tool_class.new }

  describe 'module inclusion' do
    it 'includes RubyLLMToolOverrides when inheriting from RubyLLM::Tool' do
      expect(tool_class.included_modules).to include(EasyTalk::Extensions::RubyLLMToolOverrides)
    end
  end

  describe '#description' do
    it 'returns the EasyTalk schema description' do
      expect(tool_instance.description).to eq('Gets current weather for a location')
    end

    context 'without description in schema' do
      let(:tool_class) do
        Class.new(RubyLLM::Tool) do
          include EasyTalk::Model

          def self.name
            'SimpleTool'
          end

          define_schema do
            property :input, String
          end

          def execute(input:)
            input
          end
        end
      end

      it 'returns a default description' do
        expect(tool_instance.description).to eq('Tool: SimpleTool')
      end
    end
  end

  describe '#params_schema' do
    it 'returns the EasyTalk JSON schema' do
      schema = tool_instance.params_schema
      expect(schema).to be_a(Hash)
      expect(schema['properties']).to have_key('latitude')
      expect(schema['properties']).to have_key('longitude')
    end
  end

  describe '#to_json_schema' do
    it 'returns the RubyLLM-compatible schema format' do
      json_schema = tool_instance.to_json_schema
      expect(json_schema.keys).to contain_exactly(:name, :description, :schema)
      expect(json_schema[:name]).to eq('WeatherTool')
      expect(json_schema[:description]).to eq('Gets current weather for a location')
      expect(json_schema[:schema]['properties']).to have_key('latitude')
    end
  end
end
