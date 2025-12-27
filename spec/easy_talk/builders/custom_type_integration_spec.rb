# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Custom Type Registration Integration' do
  # Define a custom Money class
  let(:money_class) do
    Class.new do
      def self.name = 'Money'

      attr_reader :amount, :currency

      def initialize(amount, currency = 'USD')
        @amount = amount
        @currency = currency
      end
    end
  end

  # Define a custom builder for Money type
  let(:money_builder_class) do
    Class.new(EasyTalk::Builders::BaseBuilder) do
      def self.name = 'MoneySchemaBuilder'

      def self.valid_options
        @valid_options ||= {
          currency: { type: T.nilable(String), key: :currency },
          min_amount: { type: T.nilable(Numeric), key: :minimum },
          max_amount: { type: T.nilable(Numeric), key: :maximum }
        }.freeze
      end

      def initialize(name, constraints = {})
        schema = {
          type: 'object',
          properties: {
            amount: { type: 'number' },
            currency: { type: 'string' }
          },
          required: %w[amount currency]
        }
        super(name, schema, constraints, self.class.valid_options)
      end
    end
  end

  # Define a GeoPoint builder for testing collection types
  let(:geo_point_class) do
    Class.new do
      def self.name = 'GeoPoint'
    end
  end

  let(:geo_point_builder_class) do
    Class.new(EasyTalk::Builders::BaseBuilder) do
      def self.name = 'GeoPointBuilder'

      def self.valid_options
        @valid_options ||= {}.freeze
      end

      def initialize(name, constraints = {})
        schema = {
          type: 'object',
          properties: {
            latitude: { type: 'number', minimum: -90, maximum: 90 },
            longitude: { type: 'number', minimum: -180, maximum: 180 }
          },
          required: %w[latitude longitude]
        }
        super(name, schema, constraints, self.class.valid_options)
      end
    end
  end

  after do
    # Clean up custom registrations after each test
    EasyTalk::Builders::Registry.unregister('Money')
    EasyTalk::Builders::Registry.unregister('GeoPoint')
  end

  describe 'registering custom types via EasyTalk.register_type' do
    before do
      EasyTalk.register_type(money_class, money_builder_class)
    end

    it 'allows using custom types in schema definitions' do
      money_type = money_class
      test_model = Class.new do
        include EasyTalk::Model

        def self.name = 'Invoice'

        define_schema do
          property :total, money_type
        end
      end

      schema = test_model.json_schema
      expect(schema['properties']['total']['type']).to eq('object')
      expect(schema['properties']['total']['properties']['amount']['type']).to eq('number')
      expect(schema['properties']['total']['properties']['currency']['type']).to eq('string')
    end

    it 'supports constraints on custom types' do
      money_type = money_class
      test_model = Class.new do
        include EasyTalk::Model

        def self.name = 'Payment'

        define_schema do
          property :amount, money_type, description: 'Payment amount'
        end
      end

      schema = test_model.json_schema
      expect(schema['properties']['amount']['description']).to eq('Payment amount')
    end
  end

  describe 'registering custom types via configuration block' do
    before do
      EasyTalk.configure do |config|
        config.register_type money_class, money_builder_class
      end
    end

    it 'registers the type successfully' do
      expect(EasyTalk::Builders::Registry.registered?('Money')).to be true
    end

    it 'allows using the registered type in models' do
      money_type = money_class
      test_model = Class.new do
        include EasyTalk::Model

        def self.name = 'Order'

        define_schema do
          property :price, money_type
        end
      end

      schema = test_model.json_schema
      expect(schema['properties']['price']['type']).to eq('object')
    end
  end

  describe 'overriding built-in types' do
    let(:custom_string_builder) do
      Class.new(EasyTalk::Builders::BaseBuilder) do
        def self.name = 'CustomStringBuilder'

        def self.valid_options
          @valid_options ||= {}.freeze
        end

        def initialize(name, constraints = {})
          schema = { type: 'string', custom: true }
          super(name, schema, constraints, self.class.valid_options)
        end
      end
    end

    after do
      # Re-register the original String builder
      EasyTalk::Builders::Registry.register(String, EasyTalk::Builders::StringBuilder)
    end

    it 'allows overriding built-in type builders' do
      EasyTalk.register_type(String, custom_string_builder)

      test_model = Class.new do
        include EasyTalk::Model

        def self.name = 'CustomStringModel'

        define_schema do
          property :name, String
        end
      end

      schema = test_model.json_schema
      expect(schema['properties']['name']['custom']).to be true
    end
  end

  describe 'multiple custom types' do
    before do
      EasyTalk.register_type(money_class, money_builder_class)
      EasyTalk.register_type(geo_point_class, geo_point_builder_class)
    end

    it 'supports multiple custom types in a single model' do
      money_type = money_class
      geo_type = geo_point_class

      test_model = Class.new do
        include EasyTalk::Model

        def self.name = 'Store'

        define_schema do
          property :revenue, money_type
          property :location, geo_type
        end
      end

      schema = test_model.json_schema
      expect(schema['properties']['revenue']['properties']['amount']['type']).to eq('number')
      expect(schema['properties']['location']['properties']['latitude']['type']).to eq('number')
    end
  end

  describe 'error handling' do
    it 'raises ArgumentError when registering invalid builder' do
      invalid_builder = Module.new

      expect do
        EasyTalk.register_type(money_class, invalid_builder)
      end.to raise_error(ArgumentError, /Builder must respond to .new/)
    end
  end

  describe 'registry management' do
    it 'can list registered types' do
      types = EasyTalk::Builders::Registry.registered_types
      # Check that at least some built-in types are registered
      expect(types).not_to be_empty
    end

    it 'can check if a type is registered' do
      expect(EasyTalk::Builders::Registry.registered?(String)).to be true
      expect(EasyTalk::Builders::Registry.registered?('NonExistentType')).to be false
    end

    it 'can unregister a custom type' do
      EasyTalk.register_type(money_class, money_builder_class)
      expect(EasyTalk::Builders::Registry.registered?('Money')).to be true

      EasyTalk::Builders::Registry.unregister('Money')
      expect(EasyTalk::Builders::Registry.registered?('Money')).to be false
    end
  end
end
