# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'External $ref Support via $id' do
  before do
    # Reset configuration before each test
    EasyTalk.configuration.base_schema_uri = nil
    EasyTalk.configuration.auto_generate_ids = false
    EasyTalk.configuration.prefer_external_refs = false
    EasyTalk.configuration.use_refs = false
  end

  after do
    # Reset configuration after each test
    EasyTalk.instance_variable_set(:@configuration, nil)
  end

  describe 'Configuration' do
    it 'has default values for new configuration options' do
      config = EasyTalk.configuration
      expect(config.base_schema_uri).to be_nil
      expect(config.auto_generate_ids).to be false
      expect(config.prefer_external_refs).to be false
    end

    it 'allows setting configuration via configure block' do
      EasyTalk.configure do |config|
        config.base_schema_uri = 'https://example.com/schemas'
        config.auto_generate_ids = true
        config.prefer_external_refs = true
      end

      config = EasyTalk.configuration
      expect(config.base_schema_uri).to eq('https://example.com/schemas')
      expect(config.auto_generate_ids).to be true
      expect(config.prefer_external_refs).to be true
    end
  end

  describe 'Auto-generated $id' do
    let(:address) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'Address'
        end
      end
    end

    before do
      stub_const('Address', address)

      Address.define_schema do
        property :street, String
        property :city, String
      end
    end

    context 'when auto_generate_ids and base_schema_uri are configured' do
      before do
        EasyTalk.configure do |config|
          config.base_schema_uri = 'https://example.com/schemas'
          config.auto_generate_ids = true
        end
      end

      it 'generates $id from base_schema_uri and model name' do
        schema = Address.json_schema
        expect(schema['$id']).to eq('https://example.com/schemas/address')
      end

      it 'converts model name to underscore case' do
        user_profile = Class.new do
          include EasyTalk::Model

          def self.name
            'UserProfile'
          end
        end
        stub_const('UserProfile', user_profile)

        UserProfile.define_schema do
          property :username, String
        end

        schema = UserProfile.json_schema
        expect(schema['$id']).to eq('https://example.com/schemas/user_profile')
      end

      it 'handles base URI with trailing slash' do
        EasyTalk.configuration.base_schema_uri = 'https://example.com/schemas/'

        schema = Address.json_schema
        expect(schema['$id']).to eq('https://example.com/schemas/address')
      end
    end

    context 'when auto_generate_ids is false' do
      before do
        EasyTalk.configure do |config|
          config.base_schema_uri = 'https://example.com/schemas'
          config.auto_generate_ids = false
        end
      end

      it 'does not generate $id' do
        schema = Address.json_schema
        expect(schema).not_to have_key('$id')
      end
    end

    context 'when base_schema_uri is nil' do
      before do
        EasyTalk.configuration.auto_generate_ids = true
      end

      it 'does not generate $id' do
        schema = Address.json_schema
        expect(schema).not_to have_key('$id')
      end
    end

    context 'explicit schema_id overrides auto-generation' do
      let(:customer) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'Customer'
          end
        end
      end

      before do
        stub_const('Customer', customer)

        Customer.define_schema do
          schema_id 'https://custom.com/customer-schema'
          property :name, String
        end

        EasyTalk.configure do |config|
          config.base_schema_uri = 'https://example.com/schemas'
          config.auto_generate_ids = true
        end
      end

      it 'uses explicit schema_id instead of auto-generated' do
        schema = Customer.json_schema
        expect(schema['$id']).to eq('https://custom.com/customer-schema')
      end
    end
  end

  describe 'External $ref generation' do
    let(:address) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'Address'
        end
      end
    end

    let(:customer) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'Customer'
        end
      end
    end

    before do
      stub_const('Address', address)
      stub_const('Customer', customer)

      Address.define_schema do
        schema_id 'https://example.com/schemas/address'
        property :street, String
        property :city, String
      end

      Customer.define_schema do
        property :name, String
        property :address, Address
      end
    end

    context 'when prefer_external_refs is enabled' do
      before do
        EasyTalk.configure do |config|
          config.use_refs = true
          config.prefer_external_refs = true
        end
      end

      it 'uses external URI in $ref when model has explicit $id' do
        schema = Customer.json_schema
        expect(schema['properties']['address']).to eq({ '$ref' => 'https://example.com/schemas/address' })
      end

      it 'includes referenced model in $defs' do
        schema = Customer.json_schema
        expect(schema['$defs']).to have_key('Address')
        expect(schema['$defs']['Address']).to include('type' => 'object', 'properties' => a_hash_including('street', 'city'))
      end
    end

    context 'when prefer_external_refs is disabled' do
      before do
        EasyTalk.configure do |config|
          config.use_refs = true
          config.prefer_external_refs = false
        end
      end

      it 'uses local $defs reference even when model has $id' do
        schema = Customer.json_schema
        expect(schema['properties']['address']).to eq({ '$ref' => '#/$defs/Address' })
      end
    end

    context 'with auto-generated $id' do
      let(:phone) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'Phone'
          end
        end
      end

      let(:contact) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'Contact'
          end
        end
      end

      before do
        stub_const('Phone', phone)
        stub_const('Contact', contact)

        Phone.define_schema do
          property :number, String
        end

        Contact.define_schema do
          property :phone, Phone
        end

        EasyTalk.configure do |config|
          config.base_schema_uri = 'https://example.com/schemas'
          config.auto_generate_ids = true
          config.use_refs = true
          config.prefer_external_refs = true
        end
      end

      it 'uses auto-generated $id in $ref' do
        schema = Contact.json_schema
        expect(schema['properties']['phone']).to eq({ '$ref' => 'https://example.com/schemas/phone' })
      end
    end
  end

  describe 'Fallback to local $defs when no $id available' do
    let(:address) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'Address'
        end
      end
    end

    let(:customer) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'Customer'
        end
      end
    end

    before do
      stub_const('Address', address)
      stub_const('Customer', customer)

      Address.define_schema do
        property :street, String
      end

      Customer.define_schema do
        property :address, Address
      end

      EasyTalk.configure do |config|
        config.use_refs = true
        config.prefer_external_refs = true
        # NOTE: no base_schema_uri or auto_generate_ids, and Address has no explicit schema_id
      end
    end

    it 'falls back to local #/$defs reference when model has no $id' do
      schema = Customer.json_schema
      expect(schema['properties']['address']).to eq({ '$ref' => '#/$defs/Address' })
    end
  end

  describe 'Integration with typed arrays' do
    let(:item) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'Item'
        end
      end
    end

    let(:order) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'Order'
        end
      end
    end

    before do
      stub_const('Item', item)
      stub_const('Order', order)

      Item.define_schema do
        schema_id 'https://example.com/schemas/item'
        property :name, String
      end

      Order.define_schema do
        property :items, T::Array[Item]
      end

      EasyTalk.configure do |config|
        config.use_refs = true
        config.prefer_external_refs = true
      end
    end

    it 'uses external ref in array items' do
      schema = Order.json_schema
      expect(schema['properties']['items']['items']).to eq({ '$ref' => 'https://example.com/schemas/item' })
    end
  end

  describe 'Integration with nilable types' do
    let(:address) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'Address'
        end
      end
    end

    let(:customer) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'Customer'
        end
      end
    end

    before do
      stub_const('Address', address)
      stub_const('Customer', customer)

      Address.define_schema do
        schema_id 'https://example.com/schemas/address'
        property :street, String
      end

      Customer.define_schema do
        property :address, T.nilable(Address)
      end

      EasyTalk.configure do |config|
        config.use_refs = true
        config.prefer_external_refs = true
      end
    end

    it 'uses external ref in anyOf for nilable types' do
      schema = Customer.json_schema
      expect(schema['properties']['address']['anyOf']).to include(
        { '$ref' => 'https://example.com/schemas/address' },
        { 'type' => 'null' }
      )
    end
  end

  describe 'Integration with composition types' do
    let(:email_contact) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'EmailContact'
        end
      end
    end

    let(:phone_contact) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'PhoneContact'
        end
      end
    end

    let(:user) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'User'
        end
      end
    end

    before do
      stub_const('EmailContact', email_contact)
      stub_const('PhoneContact', phone_contact)
      stub_const('User', user)

      EmailContact.define_schema do
        schema_id 'https://example.com/schemas/email_contact'
        property :email, String
      end

      PhoneContact.define_schema do
        schema_id 'https://example.com/schemas/phone_contact'
        property :phone, String
      end

      User.define_schema do
        property :contact, T::OneOf[EmailContact, PhoneContact]
      end

      EasyTalk.configure do |config|
        config.use_refs = true
        config.prefer_external_refs = true
      end
    end

    it 'uses external refs in oneOf composition' do
      schema = User.json_schema
      expect(schema['properties']['contact']['oneOf']).to include(
        { '$ref' => 'https://example.com/schemas/email_contact' },
        { '$ref' => 'https://example.com/schemas/phone_contact' }
      )
    end
  end

  describe 'Mixed local and external refs' do
    let(:address) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'Address'
        end
      end
    end

    let(:phone) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'Phone'
        end
      end
    end

    let(:customer) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'Customer'
        end
      end
    end

    before do
      stub_const('Address', address)
      stub_const('Phone', phone)
      stub_const('Customer', customer)

      Address.define_schema do
        schema_id 'https://example.com/schemas/address'
        property :street, String
      end

      Phone.define_schema do
        # No schema_id, should use local ref
        property :number, String
      end

      Customer.define_schema do
        property :address, Address
        property :phone, Phone
      end

      EasyTalk.configure do |config|
        config.use_refs = true
        config.prefer_external_refs = true
      end
    end

    it 'uses external ref for models with $id and local ref for models without' do
      schema = Customer.json_schema
      expect(schema['properties']['address']).to eq({ '$ref' => 'https://example.com/schemas/address' })
      expect(schema['properties']['phone']).to eq({ '$ref' => '#/$defs/Phone' })
    end

    it 'includes both models in $defs' do
      schema = Customer.json_schema
      expect(schema['$defs']).to have_key('Address')
      expect(schema['$defs']).to have_key('Phone')
    end
  end

  describe 'Per-property ref override with external refs' do
    let(:address) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'Address'
        end
      end
    end

    let(:customer) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'Customer'
        end
      end
    end

    before do
      stub_const('Address', address)
      stub_const('Customer', customer)

      Address.define_schema do
        schema_id 'https://example.com/schemas/address'
        property :street, String
      end

      Customer.define_schema do
        property :address, Address, ref: false
      end

      EasyTalk.configure do |config|
        config.use_refs = true
        config.prefer_external_refs = true
      end
    end

    it 'inlines schema when ref: false even with external refs enabled' do
      schema = Customer.json_schema
      expect(schema['properties']['address']).to include('type' => 'object')
      expect(schema['properties']['address']).not_to have_key('$ref')
    end
  end

  describe 'Backwards compatibility' do
    let(:address) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'Address'
        end
      end
    end

    let(:customer) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'Customer'
        end
      end
    end

    before do
      stub_const('Address', address)
      stub_const('Customer', customer)

      Address.define_schema do
        property :street, String
      end

      Customer.define_schema do
        property :address, Address
      end
    end

    context 'with default configuration' do
      it 'inlines nested models by default' do
        schema = Customer.json_schema
        expect(schema['properties']['address']).to include('type' => 'object')
        expect(schema['properties']['address']).not_to have_key('$ref')
      end
    end

    context 'with only use_refs enabled' do
      before do
        EasyTalk.configuration.use_refs = true
      end

      it 'uses local #/$defs references' do
        schema = Customer.json_schema
        expect(schema['properties']['address']).to eq({ '$ref' => '#/$defs/Address' })
      end
    end
  end

  describe 'Schema ID precedence' do
    let(:model_with_explicit_id) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'Model'
        end
      end
    end

    before do
      stub_const('Model', model_with_explicit_id)

      Model.define_schema do
        schema_id 'https://explicit.com/model'
        property :name, String
      end
    end

    context 'explicit schema_id takes precedence over auto-generation' do
      before do
        EasyTalk.configure do |config|
          config.base_schema_uri = 'https://example.com/schemas'
          config.auto_generate_ids = true
        end
      end

      it 'uses explicit schema_id' do
        schema = Model.json_schema
        expect(schema['$id']).to eq('https://explicit.com/model')
      end
    end

    context 'explicit schema_id takes precedence over global schema_id' do
      before do
        EasyTalk.configuration.schema_id = 'https://global.com/default'
      end

      it 'uses explicit schema_id' do
        schema = Model.json_schema
        expect(schema['$id']).to eq('https://explicit.com/model')
      end
    end

    context 'auto-generated takes precedence over global schema_id' do
      let(:model_without_explicit_id) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'ModelWithoutId'
          end
        end
      end

      before do
        stub_const('ModelWithoutId', model_without_explicit_id)

        ModelWithoutId.define_schema do
          property :name, String
        end

        EasyTalk.configure do |config|
          config.schema_id = 'https://global.com/default'
          config.base_schema_uri = 'https://example.com/schemas'
          config.auto_generate_ids = true
        end
      end

      it 'uses auto-generated schema_id' do
        schema = ModelWithoutId.json_schema
        expect(schema['$id']).to eq('https://example.com/schemas/model_without_id')
      end
    end
  end

  describe 'URI format validation' do
    let(:address) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'Address'
        end
      end
    end

    before do
      stub_const('Address', address)

      Address.define_schema do
        property :street, String
      end

      EasyTalk.configure do |config|
        config.auto_generate_ids = true
      end
    end

    it 'supports absolute HTTP URIs' do
      EasyTalk.configuration.base_schema_uri = 'http://example.com/schemas'
      schema = Address.json_schema
      expect(schema['$id']).to eq('http://example.com/schemas/address')
    end

    it 'supports absolute HTTPS URIs' do
      EasyTalk.configuration.base_schema_uri = 'https://example.com/schemas'
      schema = Address.json_schema
      expect(schema['$id']).to eq('https://example.com/schemas/address')
    end

    it 'supports relative URIs' do
      EasyTalk.configuration.base_schema_uri = '/schemas'
      schema = Address.json_schema
      expect(schema['$id']).to eq('/schemas/address')
    end

    it 'supports URNs' do
      EasyTalk.configuration.base_schema_uri = 'urn:example:schemas'
      schema = Address.json_schema
      expect(schema['$id']).to eq('urn:example:schemas/address')
    end
  end
end
