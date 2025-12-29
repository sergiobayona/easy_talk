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
  # Mock RubyLLM::Tool for testing without requiring the gem
  before do
    # Define Halt class first
    halt_class = Class.new do
      attr_reader :content

      def initialize(content)
        @content = content
      end
    end

    # Define Tool class with reference to Halt
    tool_class = Class.new do
      define_method(:name) do
        klass_name = self.class.name
        normalized = klass_name.to_s.dup.force_encoding('UTF-8').unicode_normalize(:nfkd)
        normalized.encode('ASCII', replace: '')
                  .gsub(/[^a-zA-Z0-9_-]/, '-')
                  .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
                  .gsub(/([a-z\d])([A-Z])/, '\1_\2')
                  .downcase
                  .delete_suffix('_tool')
      end

      define_method(:call) do |args = {}|
        execute(**args.transform_keys(&:to_sym))
      end

      define_method(:execute) do |**_args|
        raise NotImplementedError, 'Subclasses must implement #execute'
      end

      define_method(:provider_params) do
        {}
      end

      define_method(:parameters) do
        {}
      end
    end

    # Store halt_class for use in halt method
    tool_class.define_method(:halt) do |message|
      halt_class.new(message)
    end
    tool_class.send(:protected, :halt)

    stub_const('RubyLLM::Tool', tool_class)
    stub_const('RubyLLM::Tool::Halt', halt_class)
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

      def execute(latitude:, longitude:)
        halt "Weather at #{latitude}, #{longitude}"
      end
    end
  end

  let(:tool_instance) { tool_class.new }

  describe 'inheritance from RubyLLM::Tool' do
    it 'inherits from RubyLLM::Tool' do
      expect(tool_class.superclass).to eq(RubyLLM::Tool)
    end

    it 'includes EasyTalk::Model' do
      expect(tool_class.included_modules).to include(EasyTalk::Model)
    end

    it 'includes RubyLLMToolOverrides' do
      expect(tool_class.included_modules).to include(EasyTalk::Extensions::RubyLLMToolOverrides)
    end
  end

  describe '#name' do
    it 'uses RubyLLM::Tool#name (not overridden)' do
      expect(tool_instance.name).to eq('weather')
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

  describe '#call and #execute' do
    it 'uses RubyLLM::Tool#call which delegates to execute' do
      result = tool_instance.call(latitude: '52.52', longitude: '13.405')
      expect(result).to be_a(RubyLLM::Tool::Halt)
      expect(result.content).to eq('Weather at 52.52, 13.405')
    end

    it 'converts string keys to symbols' do
      result = tool_instance.call('latitude' => '40.7', 'longitude' => '-74.0')
      expect(result).to be_a(RubyLLM::Tool::Halt)
      expect(result.content).to eq('Weather at 40.7, -74.0')
    end
  end

  describe '#halt' do
    it 'provides access to RubyLLM::Tool#halt' do
      result = tool_instance.call(latitude: '40.7', longitude: '-74.0')
      expect(result).to be_a(RubyLLM::Tool::Halt)
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

  describe 'provider_params (inherited from RubyLLM::Tool)' do
    it 'responds to provider_params' do
      expect(tool_instance).to respond_to(:provider_params)
    end
  end

  describe 'parameters (inherited from RubyLLM::Tool)' do
    it 'responds to parameters' do
      expect(tool_instance).to respond_to(:parameters)
    end
  end
end
