# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'additionalProperties with schema objects' do
  describe 'schema generation' do
    context 'with String type' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'Config'

          define_schema do
            property :name, String
            additional_properties String
          end
        end
      end

      it 'generates type schema for String' do
        expect(test_class.json_schema['additionalProperties']).to eq({ 'type' => 'string' })
      end

      it 'includes defined properties' do
        expect(test_class.json_schema['properties']['name']).to eq({ 'type' => 'string' })
      end

      it 'marks name as required' do
        expect(test_class.json_schema['required']).to eq(['name'])
      end
    end

    context 'with Integer type' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'NumericConfig'

          define_schema do
            property :id, Integer
            additional_properties Integer
          end
        end
      end

      it 'generates type schema for Integer' do
        expect(test_class.json_schema['additionalProperties']).to eq({ 'type' => 'integer' })
      end
    end

    context 'with Float type' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'FloatConfig'

          define_schema do
            property :value, Float
            additional_properties Float
          end
        end
      end

      it 'generates type schema for Float' do
        expect(test_class.json_schema['additionalProperties']).to eq({ 'type' => 'number' })
      end
    end

    context 'with constraints' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'ConstrainedConfig'

          define_schema do
            property :name, String
            additional_properties Integer, minimum: 0, maximum: 100
          end
        end
      end

      it 'generates schema with constraints' do
        expect(test_class.json_schema['additionalProperties']).to eq({
                                                                       'type' => 'integer',
                                                                       'minimum' => 0,
                                                                       'maximum' => 100
                                                                     })
      end
    end

    context 'with String constraints' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'StringConstrainedConfig'

          define_schema do
            property :name, String
            additional_properties String, min_length: 3, max_length: 50
          end
        end
      end

      it 'generates schema with string constraints' do
        expect(test_class.json_schema['additionalProperties']).to eq({
                                                                       'type' => 'string',
                                                                       'minLength' => 3,
                                                                       'maxLength' => 50
                                                                     })
      end
    end

    context 'with pattern constraint' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'PatternConfig'

          define_schema do
            property :name, String
            additional_properties String, pattern: '^[A-Z]+$'
          end
        end
      end

      it 'generates schema with pattern constraint' do
        schema = test_class.json_schema['additionalProperties']
        expect(schema['type']).to eq('string')
        # Pattern gets normalized by the builder (anchors added)
        expect(schema['pattern']).to include('[A-Z]+')
      end
    end

    context 'with nested EasyTalk model' do
      let(:address_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'Address'

          define_schema do
            property :street, String
            property :city, String
          end
        end
      end

      let(:test_class) do
        addr_class = address_class
        Class.new do
          include EasyTalk::Model

          def self.name = 'Person'

          define_schema do
            property :name, String
            additional_properties addr_class
          end
        end
      end

      it 'generates inline schema for model type' do
        schema = test_class.json_schema['additionalProperties']
        expect(schema['type']).to eq('object')
        expect(schema['properties']['street']).to eq({ 'type' => 'string' })
        expect(schema['properties']['city']).to eq({ 'type' => 'string' })
      end
    end
  end

  describe 'backwards compatibility' do
    context 'with boolean true' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'BooleanTrueConfig'

          define_schema do
            property :name, String
            additional_properties true
          end
        end
      end

      it 'generates schema with boolean true' do
        expect(test_class.json_schema['additionalProperties']).to be true
      end
    end

    context 'with boolean false' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'BooleanFalseConfig'

          define_schema do
            property :name, String
            additional_properties false
          end
        end
      end

      it 'generates schema with boolean false' do
        expect(test_class.json_schema['additionalProperties']).to be false
      end
    end

    context 'with default config' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'DefaultConfig'

          define_schema do
            property :name, String
          end
        end
      end

      it 'uses default_additional_properties from config' do
        expect(test_class.json_schema['additionalProperties']).to be false
      end
    end
  end

  describe 'runtime behavior' do
    context 'with type constraints' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'TypedConfig'

          define_schema do
            property :name, String
            additional_properties String
          end
        end
      end

      it 'allows setting additional properties' do
        instance = test_class.new(name: 'test')
        expect { instance.label = 'my label' }.not_to raise_error
        expect(instance.label).to eq('my label')
      end

      it 'allows any value (type validation deferred to schema validation)' do
        instance = test_class.new(name: 'test')
        # Runtime does not enforce types - that's handled by JSON Schema validation
        expect { instance.count = 42 }.not_to raise_error
        expect(instance.count).to eq(42)
      end

      it 'includes additional properties in as_json' do
        instance = test_class.new(name: 'test')
        instance.label = 'my label'
        expect(instance.as_json).to eq({ 'name' => 'test', 'label' => 'my label' })
      end

      it 'includes additional properties in to_h' do
        instance = test_class.new(name: 'test')
        instance.label = 'my label'
        # Both defined and additional properties use string keys
        expect(instance.to_h).to eq({ 'name' => 'test', 'label' => 'my label' })
      end
    end

    context 'with boolean true (no type constraint)' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'FlexibleConfig'

          define_schema do
            property :name, String
            additional_properties true
          end
        end
      end

      it 'allows any type for additional properties' do
        instance = test_class.new(name: 'test')
        expect { instance.count = 42 }.not_to raise_error
        expect { instance.label = 'string' }.not_to raise_error
        expect { instance.ratio = 3.14 }.not_to raise_error
        expect(instance.count).to eq(42)
        expect(instance.label).to eq('string')
        expect(instance.ratio).to eq(3.14)
      end
    end

    context 'with boolean false' do
      let(:test_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'StrictConfig'

          define_schema do
            property :name, String
            additional_properties false
          end
        end
      end

      it 'raises error for additional properties' do
        instance = test_class.new(name: 'test')
        expect do
          instance.extra = 'not allowed'
        end.to raise_error(NoMethodError)
      end
    end
  end

  describe 'respond_to? behavior' do
    let(:test_class) do
      Class.new do
        include EasyTalk::Model

        def self.name = 'RespondConfig'

        define_schema do
          property :name, String
          additional_properties String
        end
      end
    end

    it 'responds to setter for any property name' do
      instance = test_class.new(name: 'test')
      expect(instance.respond_to?(:custom_field=)).to be true
    end

    it 'responds to getter after setting property' do
      instance = test_class.new(name: 'test')
      instance.custom_field = 'value'
      expect(instance.respond_to?(:custom_field)).to be true
    end

    it 'does not respond to getter before setting property' do
      instance = test_class.new(name: 'test')
      expect(instance.respond_to?(:custom_field)).to be false
    end
  end
end
