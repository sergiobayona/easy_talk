# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::Builders::CompositionBuilder do
  let(:person_model) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'Person'
      end

      define_schema do
        property :name, String
        property :age, Integer
      end
    end
  end

  let(:employee_model) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'Employee'
      end

      define_schema do
        property :employee_id, String
        property :department, String
      end
    end
  end

  describe '#composer_keyword' do
    it 'returns nil for base CompositionBuilder' do
      composer = T::AllOf[person_model]
      builder = described_class.new(:combined, composer, {})
      # Base class returns nil because its class name is 'CompositionBuilder' not in the mapping
      expect(builder.composer_keyword).to be_nil
    end
  end

  describe '#items' do
    it 'returns the items from the composition type' do
      composer = T::AllOf[person_model, employee_model]
      builder = described_class.new(:combined, composer, {})

      expect(builder.items).to eq([person_model, employee_model])
    end

    it 'returns single item when one type provided' do
      composer = T::AllOf[person_model]
      builder = described_class.new(:single, composer, {})

      expect(builder.items).to eq([person_model])
    end
  end

  describe '.collection_type?' do
    it 'returns true' do
      expect(described_class.collection_type?).to be true
    end
  end

  describe 'COMPOSER_TO_KEYWORD' do
    it 'maps AllOfBuilder to allOf' do
      expect(described_class::COMPOSER_TO_KEYWORD['AllOfBuilder']).to eq('allOf')
    end

    it 'maps AnyOfBuilder to anyOf' do
      expect(described_class::COMPOSER_TO_KEYWORD['AnyOfBuilder']).to eq('anyOf')
    end

    it 'maps OneOfBuilder to oneOf' do
      expect(described_class::COMPOSER_TO_KEYWORD['OneOfBuilder']).to eq('oneOf')
    end
  end
end

RSpec.describe EasyTalk::Builders::CompositionBuilder::AllOfBuilder do
  let(:person_model) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'Person'
      end

      define_schema do
        property :name, String
        property :age, Integer
      end
    end
  end

  let(:employee_model) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'Employee'
      end

      define_schema do
        property :employee_id, String
        property :department, String
      end
    end
  end

  describe '#build' do
    it 'generates schema with allOf keyword' do
      composer = T::AllOf[person_model, employee_model]
      builder = described_class.new(:combined, composer, {})
      result = builder.build

      expect(result[:type]).to eq('object')
      expect(result).to have_key('allOf')
    end

    it 'includes schemas for all composed types' do
      composer = T::AllOf[person_model, employee_model]
      builder = described_class.new(:combined, composer, {})
      result = builder.build

      schemas = result['allOf']
      expect(schemas.length).to eq(2)
    end

    it 'includes model schemas with properties' do
      composer = T::AllOf[person_model]
      builder = described_class.new(:person_info, composer, {})
      result = builder.build

      schemas = result['allOf']
      expect(schemas.first).to include(
        type: 'object',
        properties: hash_including(:name, :age)
      )
    end

    it 'stores result in context with property name as key' do
      composer = T::AllOf[person_model]
      builder = described_class.new(:combined, composer, {})
      builder.build

      context = builder.instance_variable_get(:@context)
      expect(context).to have_key(:combined)
      expect(context[:combined]).to have_key('allOf')
    end
  end

  describe '#composer_keyword' do
    it 'returns allOf' do
      composer = T::AllOf[person_model]
      builder = described_class.new(:test, composer, {})
      expect(builder.composer_keyword).to eq('allOf')
    end
  end

  describe '#schemas' do
    it 'returns array of schemas from composed types' do
      composer = T::AllOf[person_model, employee_model]
      builder = described_class.new(:combined, composer, {})

      schemas = builder.schemas
      expect(schemas).to be_an(Array)
      expect(schemas.length).to eq(2)
    end

    context 'with ref constraints enabled' do
      it 'uses $ref when ref constraint is true' do
        composer = T::AllOf[person_model]
        builder = described_class.new(:combined, composer, { ref: true })

        schemas = builder.schemas
        expect(schemas.first).to have_key(:$ref)
      end
    end

    context 'with primitive types' do
      it 'maps primitive types to JSON Schema types' do
        composer = T::AllOf[String, Integer]
        builder = described_class.new(:primitives, composer, {})

        schemas = builder.schemas
        expect(schemas).to include({ type: 'string' })
        expect(schemas).to include({ type: 'integer' })
      end
    end
  end

  describe '.collection_type?' do
    it 'returns true' do
      expect(described_class.collection_type?).to be true
    end
  end
end

RSpec.describe EasyTalk::Builders::CompositionBuilder::AnyOfBuilder do
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

  let(:phone_model) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'Phone'
      end

      define_schema do
        property :number, String
      end
    end
  end

  describe '#build' do
    it 'generates schema with anyOf keyword' do
      composer = T::AnyOf[address_model, phone_model]
      builder = described_class.new(:contact, composer, {})
      result = builder.build

      expect(result[:type]).to eq('object')
      expect(result).to have_key('anyOf')
    end

    it 'includes schemas for all composed types' do
      composer = T::AnyOf[address_model, phone_model]
      builder = described_class.new(:contact, composer, {})
      result = builder.build

      schemas = result['anyOf']
      expect(schemas.length).to eq(2)
    end

    it 'stores result in context with property name as key' do
      composer = T::AnyOf[address_model]
      builder = described_class.new(:contact, composer, {})
      builder.build

      context = builder.instance_variable_get(:@context)
      expect(context).to have_key(:contact)
      expect(context[:contact]).to have_key('anyOf')
    end
  end

  describe '#composer_keyword' do
    it 'returns anyOf' do
      composer = T::AnyOf[address_model]
      builder = described_class.new(:test, composer, {})
      expect(builder.composer_keyword).to eq('anyOf')
    end
  end

  describe '#schemas' do
    it 'returns array of schemas from composed types' do
      composer = T::AnyOf[address_model, phone_model]
      builder = described_class.new(:contact, composer, {})

      schemas = builder.schemas
      expect(schemas).to be_an(Array)
      expect(schemas.length).to eq(2)
    end
  end

  describe '.collection_type?' do
    it 'returns true' do
      expect(described_class.collection_type?).to be true
    end
  end
end

RSpec.describe EasyTalk::Builders::CompositionBuilder::OneOfBuilder do
  let(:credit_card_model) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'CreditCard'
      end

      define_schema do
        property :card_number, String
        property :expiry, String
      end
    end
  end

  let(:bank_account_model) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'BankAccount'
      end

      define_schema do
        property :account_number, String
        property :routing_number, String
      end
    end
  end

  describe '#build' do
    it 'generates schema with oneOf keyword' do
      composer = T::OneOf[credit_card_model, bank_account_model]
      builder = described_class.new(:payment_method, composer, {})
      result = builder.build

      expect(result[:type]).to eq('object')
      expect(result).to have_key('oneOf')
    end

    it 'includes schemas for all composed types' do
      composer = T::OneOf[credit_card_model, bank_account_model]
      builder = described_class.new(:payment_method, composer, {})
      result = builder.build

      schemas = result['oneOf']
      expect(schemas.length).to eq(2)
    end

    it 'stores result in context with property name as key' do
      composer = T::OneOf[credit_card_model]
      builder = described_class.new(:payment_method, composer, {})
      builder.build

      context = builder.instance_variable_get(:@context)
      expect(context).to have_key(:payment_method)
      expect(context[:payment_method]).to have_key('oneOf')
    end
  end

  describe '#composer_keyword' do
    it 'returns oneOf' do
      composer = T::OneOf[credit_card_model]
      builder = described_class.new(:test, composer, {})
      expect(builder.composer_keyword).to eq('oneOf')
    end
  end

  describe '#schemas' do
    it 'returns array of schemas from composed types' do
      composer = T::OneOf[credit_card_model, bank_account_model]
      builder = described_class.new(:payment_method, composer, {})

      schemas = builder.schemas
      expect(schemas).to be_an(Array)
      expect(schemas.length).to eq(2)
    end

    it 'includes correct properties for each model' do
      composer = T::OneOf[credit_card_model, bank_account_model]
      builder = described_class.new(:payment_method, composer, {})

      schemas = builder.schemas
      expect(schemas).to include(
        hash_including(properties: hash_including(:card_number, :expiry))
      )
      expect(schemas).to include(
        hash_including(properties: hash_including(:account_number, :routing_number))
      )
    end
  end

  describe '.collection_type?' do
    it 'returns true' do
      expect(described_class.collection_type?).to be true
    end
  end
end

RSpec.describe 'CompositionBuilder initialization' do
  let(:sample_model) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'SampleModel'
      end

      define_schema do
        property :field, String
      end
    end
  end

  it 'stores name, type, and constraints' do
    composer = T::AllOf[sample_model]
    builder = EasyTalk::Builders::CompositionBuilder::AllOfBuilder.new(
      :test_field,
      composer,
      { ref: true }
    )

    expect(builder.instance_variable_get(:@name)).to eq(:test_field)
    expect(builder.instance_variable_get(:@type)).to eq(composer)
    expect(builder.instance_variable_get(:@constraints)).to eq({ ref: true })
  end

  it 'extracts composer type from class name' do
    composer = T::AllOf[sample_model]
    builder = EasyTalk::Builders::CompositionBuilder::AllOfBuilder.new(:test, composer, {})

    expect(builder.instance_variable_get(:@composer_type)).to eq('AllOfBuilder')
  end

  it 'initializes empty context' do
    composer = T::AllOf[sample_model]
    builder = EasyTalk::Builders::CompositionBuilder::AllOfBuilder.new(:test, composer, {})

    expect(builder.instance_variable_get(:@context)).to eq({})
  end
end
