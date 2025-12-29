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

RSpec.describe EasyTalk::Extensions::RubyLLMToolInstanceMethods do
  let(:tool_class) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'WeatherTool'
      end

      define_schema do
        description 'Gets current weather for a location'
        property :latitude, String, description: 'Latitude'
        property :longitude, String, description: 'Longitude'
      end

      def execute(latitude:, longitude:)
        "Weather at #{latitude}, #{longitude}"
      end
    end
  end

  let(:tool_instance) { tool_class.new }

  describe '#name' do
    it 'returns a snake_case normalized name' do
      expect(tool_instance.name).to eq('weather')
    end

    it 'removes _tool suffix' do
      expect(tool_instance.name).not_to include('tool')
    end

    context 'with CamelCase class name' do
      let(:tool_class) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'MyAwesomeTool'
          end

          define_schema do
            property :input, String
          end
        end
      end

      it 'converts to snake_case and removes _tool' do
        expect(tool_instance.name).to eq('my_awesome')
      end
    end

    context 'with anonymous class' do
      let(:tool_class) do
        Class.new do
          include EasyTalk::Model

          def self.name
            nil
          end
        end
      end

      it 'returns unnamed_tool' do
        instance = tool_class.allocate
        instance.instance_variable_set(:@additional_properties, {})
        expect(instance.name).to eq('unnamed_tool')
      end
    end
  end

  describe '#description' do
    it 'returns the schema description' do
      expect(tool_instance.description).to eq('Gets current weather for a location')
    end

    context 'without description in schema' do
      let(:tool_class) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'SimpleTool'
          end

          define_schema do
            property :input, String
          end
        end
      end

      it 'returns a default description' do
        expect(tool_instance.description).to eq('Tool: SimpleTool')
      end
    end
  end

  describe '#params_schema' do
    it 'returns the JSON schema for the tool' do
      schema = tool_instance.params_schema
      expect(schema).to be_a(Hash)
      expect(schema['properties']).to have_key('latitude')
      expect(schema['properties']).to have_key('longitude')
    end
  end

  describe '#call' do
    it 'passes args as keyword arguments to execute' do
      result = tool_instance.call(latitude: '52.52', longitude: '13.405')
      expect(result).to eq('Weather at 52.52, 13.405')
    end

    it 'converts string keys to symbols' do
      result = tool_instance.call('latitude' => '40.7', 'longitude' => '-74.0')
      expect(result).to eq('Weather at 40.7, -74.0')
    end
  end
end
