# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::Builders::ObjectBuilder do
  describe '#build' do
    context 'with basic schema generation' do
      let(:simple_model) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'SimpleModel'
          end

          define_schema do
            property :name, String
            property :age, Integer
          end
        end
      end

      it 'generates basic object schema with properties' do
        schema = simple_model.json_schema
        expect(schema['type']).to eq('object')
        expect(schema['properties']).to have_key('name')
        expect(schema['properties']).to have_key('age')
      end

      it 'includes type information for each property' do
        schema = simple_model.json_schema
        expect(schema['properties']['name']['type']).to eq('string')
        expect(schema['properties']['age']['type']).to eq('integer')
      end

      it 'marks all properties as required by default' do
        schema = simple_model.json_schema
        expect(schema['required']).to contain_exactly('name', 'age')
      end

      it 'sets additionalProperties to false by default' do
        schema = simple_model.json_schema
        expect(schema['additionalProperties']).to be false
      end
    end

    context 'with optional properties' do
      let(:model_with_optional) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'ModelWithOptional'
          end

          define_schema do
            property :required_field, String
            property :optional_field, String, optional: true
          end
        end
      end

      it 'excludes optional properties from required array' do
        schema = model_with_optional.json_schema
        expect(schema['required']).to eq(['required_field'])
        expect(schema['required']).not_to include('optional_field')
      end

      it 'still includes optional properties in properties hash' do
        schema = model_with_optional.json_schema
        expect(schema['properties']).to have_key('optional_field')
      end
    end

    context 'with :as property constraint' do
      let(:model_with_alias) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'ModelWithAlias'
          end

          define_schema do
            property :internal_name, String, as: :display_name
          end
        end
      end

      it 'uses the :as value as the property name in schema' do
        schema = model_with_alias.json_schema
        expect(schema['properties']).to have_key('display_name')
        expect(schema['properties']).not_to have_key('internal_name')
      end

      it 'includes aliased property in required array' do
        schema = model_with_alias.json_schema
        expect(schema['required']).to eq(['display_name'])
      end
    end

    context 'with title and description' do
      let(:documented_model) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'DocumentedModel'
          end

          define_schema do
            title 'My Model'
            description 'A well-documented model'
            property :field, String
          end
        end
      end

      it 'includes title in schema' do
        schema = documented_model.json_schema
        expect(schema['title']).to eq('My Model')
      end

      it 'includes description in schema' do
        schema = documented_model.json_schema
        expect(schema['description']).to eq('A well-documented model')
      end
    end

    context 'with additional_properties configuration' do
      let(:model_allowing_additional) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'ModelAllowingAdditional'
          end

          define_schema do
            additional_properties true
            property :known_field, String
          end
        end
      end

      it 'respects additional_properties setting' do
        schema = model_allowing_additional.json_schema
        expect(schema['additionalProperties']).to be true
      end
    end

    context 'with nested EasyTalk models' do
      let(:address_model) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'Address'
          end

          define_schema do
            property :street, String
            property :city, String
          end
        end
      end

      let(:person_model) do
        address = address_model
        Class.new do
          include EasyTalk::Model

          def self.name
            'Person'
          end

          define_schema do
            property :name, String
            property :address, address
          end
        end
      end

      it 'generates nested object schema for model properties' do
        schema = person_model.json_schema
        expect(schema['properties']['address']['type']).to eq('object')
        expect(schema['properties']['address']['properties']).to have_key('street')
        expect(schema['properties']['address']['properties']).to have_key('city')
      end
    end

    context 'with array properties' do
      let(:model_with_array) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'ModelWithArray'
          end

          define_schema do
            property :tags, T::Array[String]
            property :scores, T::Array[Integer]
          end
        end
      end

      it 'generates array schema with typed items' do
        schema = model_with_array.json_schema
        expect(schema['properties']['tags']['type']).to eq('array')
        expect(schema['properties']['tags']['items']['type']).to eq('string')
        expect(schema['properties']['scores']['items']['type']).to eq('integer')
      end
    end

    context 'with nilable properties' do
      let(:model_with_nilable) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'ModelWithNilable'
          end

          define_schema do
            property :required_value, String
            property :nullable_value, T.nilable(String)
          end
        end
      end

      it 'generates schema allowing null for nilable types' do
        schema = model_with_nilable.json_schema
        nullable_prop = schema['properties']['nullable_value']
        # Nilable types can be represented as anyOf or as type array
        if nullable_prop.key?('anyOf')
          expect(nullable_prop['anyOf']).to include({ 'type' => 'string' })
          expect(nullable_prop['anyOf']).to include({ 'type' => 'null' })
        else
          expect(nullable_prop['type']).to include('string')
          expect(nullable_prop['type']).to include('null')
        end
      end

      it 'still marks nilable properties as required by default' do
        schema = model_with_nilable.json_schema
        expect(schema['required']).to include('nullable_value')
      end
    end

    context 'with nilable_is_optional configuration' do
      let(:model_for_config) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'ModelForConfig'
          end

          define_schema do
            property :name, String
            property :nickname, T.nilable(String)
          end
        end
      end

      around do |example|
        original_setting = EasyTalk.configuration.nilable_is_optional
        example.run
        EasyTalk.configuration.nilable_is_optional = original_setting
      end

      it 'treats nilable as optional when nilable_is_optional is true' do
        EasyTalk.configuration.nilable_is_optional = true
        # Reset cached schemas
        model_for_config.instance_variable_set(:@schema, nil)
        model_for_config.instance_variable_set(:@json_schema, nil)

        schema = model_for_config.json_schema
        expect(schema['required']).to eq(['name'])
        expect(schema['required']).not_to include('nickname')
      end

      it 'keeps nilable as required when nilable_is_optional is false' do
        EasyTalk.configuration.nilable_is_optional = false
        # Reset cached schemas
        model_for_config.instance_variable_set(:@schema, nil)
        model_for_config.instance_variable_set(:@json_schema, nil)

        schema = model_for_config.json_schema
        expect(schema['required']).to include('nickname')
      end
    end

    context 'with composition types' do
      let(:base_model) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'BaseModel'
          end

          define_schema do
            property :id, Integer
          end
        end
      end

      let(:extension_model) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'ExtensionModel'
          end

          define_schema do
            property :extra, String
          end
        end
      end

      let(:composed_model) do
        base = base_model
        extension = extension_model
        Class.new do
          include EasyTalk::Model

          def self.name
            'ComposedModel'
          end

          define_schema do
            property :name, String
            compose T::AllOf[base, extension]
          end
        end
      end

      it 'includes allOf in schema' do
        schema = composed_model.json_schema
        expect(schema).to have_key('allOf')
      end

      it 'generates $defs for composed types' do
        schema = composed_model.json_schema
        expect(schema).to have_key('$defs')
        expect(schema['$defs']).to have_key('BaseModel')
        expect(schema['$defs']).to have_key('ExtensionModel')
      end
    end

    context 'with empty properties' do
      let(:empty_model) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'EmptyModel'
          end

          define_schema do
            # No properties defined
          end
        end
      end

      it 'generates valid schema with no properties' do
        schema = empty_model.json_schema
        expect(schema['type']).to eq('object')
        # Properties may be empty hash or not present
        expect(schema['properties'] || {}).to be_empty
      end

      it 'has no required array when no properties' do
        schema = empty_model.json_schema
        expect(schema['required']).to be_nil
      end
    end
  end

  describe 'schema immutability' do
    let(:model) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'TestModel'
        end

        define_schema do
          property :name, String, as: :full_name
          property :age, Integer
        end
      end
    end

    it 'does not mutate the original schema definition when building' do
      schema_definition = model.schema_definition
      original_constraints = schema_definition.schema[:properties][:name][:constraints].dup

      # Build the schema multiple times
      described_class.new(schema_definition).build
      described_class.new(schema_definition).build

      # The original constraints should remain unchanged
      expect(schema_definition.schema[:properties][:name][:constraints]).to eq(original_constraints)
    end

    it 'preserves the :as constraint in the original schema after building' do
      schema_definition = model.schema_definition

      # Build the schema
      described_class.new(schema_definition).build

      # The :as constraint should still be present
      expect(schema_definition.schema[:properties][:name][:constraints][:as]).to eq(:full_name)
    end

    it 'produces consistent JSON schema across multiple builds' do
      # Using model.json_schema calls the builder internally
      first_json = model.json_schema
      # Reset the cached schema to force rebuild
      model.instance_variable_set(:@schema, nil)
      model.instance_variable_set(:@json_schema, nil)
      second_json = model.json_schema

      expect(first_json).to eq(second_json)
    end
  end
end
