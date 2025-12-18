# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'JSON Schema $ref support' do
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

  let(:person) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'Person'
      end
    end
  end

  before do
    stub_const('Address', address)
    stub_const('Phone', phone)
    stub_const('Person', person)

    Address.define_schema do
      title 'Address'
      property :street, String
      property :city, String
    end

    Phone.define_schema do
      title 'Phone'
      property :number, String
      property :type, String
    end
  end

  after do
    # Reset configuration after each test
    EasyTalk.instance_variable_set(:@configuration, nil)
  end

  describe 'configuration' do
    describe 'EasyTalk::Configuration' do
      subject(:config) { EasyTalk::Configuration.new }

      it 'defaults use_refs to false' do
        expect(config.use_refs).to be false
      end

      it 'allows setting use_refs' do
        config.use_refs = true
        expect(config.use_refs).to be true
      end
    end

    describe 'EasyTalk.configure' do
      it 'allows configuring use_refs globally' do
        EasyTalk.configure do |config|
          config.use_refs = true
        end

        expect(EasyTalk.configuration.use_refs).to be true
      end
    end
  end

  describe 'nested model without refs (default behavior)' do
    before do
      Person.define_schema do
        title 'Person'
        property :name, String
        property :address, Address
      end
    end

    it 'inlines the nested schema by default' do
      schema = Person.json_schema

      expect(schema['properties']['address']).to include(
        'title' => 'Address',
        'type' => 'object',
        'properties' => {
          'street' => { 'type' => 'string' },
          'city' => { 'type' => 'string' }
        }
      )
      expect(schema).not_to have_key('$defs')
    end
  end

  describe 'nested model with global use_refs enabled' do
    before do
      EasyTalk.configure do |config|
        config.use_refs = true
      end

      Person.define_schema do
        title 'Person'
        property :name, String
        property :address, Address
      end
    end

    it 'uses $ref for the nested model' do
      schema = Person.json_schema

      expect(schema['properties']['address']).to eq({ '$ref' => '#/$defs/Address' })
    end

    it 'includes the nested model in $defs' do
      schema = Person.json_schema

      expect(schema['$defs']).to have_key('Address')
      expect(schema['$defs']['Address']).to include(
        'title' => 'Address',
        'type' => 'object'
      )
    end
  end

  describe 'per-property ref constraint' do
    context 'with ref: true on specific property' do
      before do
        Person.define_schema do
          title 'Person'
          property :name, String
          property :address, Address, ref: true
        end
      end

      it 'uses $ref for that property' do
        schema = Person.json_schema

        expect(schema['properties']['address']).to eq({ '$ref' => '#/$defs/Address' })
        expect(schema['$defs']).to have_key('Address')
      end
    end

    context 'with ref: false to override global config' do
      before do
        EasyTalk.configure do |config|
          config.use_refs = true
        end

        Person.define_schema do
          title 'Person'
          property :name, String
          property :address, Address, ref: false
        end
      end

      it 'inlines the schema despite global setting' do
        schema = Person.json_schema

        expect(schema['properties']['address']).to include(
          'title' => 'Address',
          'type' => 'object'
        )
        expect(schema).not_to have_key('$defs')
      end
    end
  end

  describe 'multiple nested models with refs' do
    before do
      EasyTalk.configure do |config|
        config.use_refs = true
      end

      Person.define_schema do
        title 'Person'
        property :name, String
        property :home_address, Address
        property :work_address, Address
        property :phone, Phone
      end
    end

    it 'references each model via $ref' do
      schema = Person.json_schema

      expect(schema['properties']['home_address']).to eq({ '$ref' => '#/$defs/Address' })
      expect(schema['properties']['work_address']).to eq({ '$ref' => '#/$defs/Address' })
      expect(schema['properties']['phone']).to eq({ '$ref' => '#/$defs/Phone' })
    end

    it 'includes all unique models in $defs' do
      schema = Person.json_schema

      expect(schema['$defs'].keys).to contain_exactly('Address', 'Phone')
    end
  end

  describe 'typed array with nested model refs' do
    context 'with global use_refs enabled' do
      before do
        EasyTalk.configure do |config|
          config.use_refs = true
        end

        Person.define_schema do
          title 'Person'
          property :name, String
          property :addresses, T::Array[Address]
        end
      end

      it 'uses $ref for array items' do
        schema = Person.json_schema

        expect(schema['properties']['addresses']).to eq({
                                                          'type' => 'array',
                                                          'items' => { '$ref' => '#/$defs/Address' }
                                                        })
      end

      it 'includes the model in $defs' do
        schema = Person.json_schema

        expect(schema['$defs']).to have_key('Address')
      end
    end

    context 'with per-property ref constraint' do
      before do
        Person.define_schema do
          title 'Person'
          property :name, String
          property :addresses, T::Array[Address], ref: true
        end
      end

      it 'uses $ref for array items' do
        schema = Person.json_schema

        expect(schema['properties']['addresses']['items']).to eq({ '$ref' => '#/$defs/Address' })
        expect(schema['$defs']).to have_key('Address')
      end
    end
  end

  describe 'nilable nested model with refs' do
    context 'with global use_refs enabled' do
      before do
        EasyTalk.configure do |config|
          config.use_refs = true
        end

        Person.define_schema do
          title 'Person'
          property :name, String
          property :address, T.nilable(Address)
        end
      end

      it 'uses anyOf with $ref and null type' do
        schema = Person.json_schema

        expect(schema['properties']['address']).to eq({
                                                        'anyOf' => [
                                                          { '$ref' => '#/$defs/Address' },
                                                          { 'type' => 'null' }
                                                        ]
                                                      })
      end

      it 'includes the model in $defs' do
        schema = Person.json_schema

        expect(schema['$defs']).to have_key('Address')
      end
    end

    context 'with per-property ref constraint' do
      before do
        Person.define_schema do
          title 'Person'
          property :name, String
          property :address, T.nilable(Address), ref: true
        end
      end

      it 'uses anyOf with $ref and null type' do
        schema = Person.json_schema

        expect(schema['properties']['address']).to eq({
                                                        'anyOf' => [
                                                          { '$ref' => '#/$defs/Address' },
                                                          { 'type' => 'null' }
                                                        ]
                                                      })
        expect(schema['$defs']).to have_key('Address')
      end
    end

    context 'with ref: false to override global config' do
      before do
        EasyTalk.configure do |config|
          config.use_refs = true
        end

        Person.define_schema do
          title 'Person'
          property :name, String
          property :address, T.nilable(Address), ref: false
        end
      end

      it 'inlines the schema with null type' do
        schema = Person.json_schema

        expect(schema['properties']['address']).to include(
          'title' => 'Address',
          'type' => %w[object null]
        )
        expect(schema).not_to have_key('$defs')
      end
    end
  end

  describe 'additional constraints with refs' do
    before do
      EasyTalk.configure do |config|
        config.use_refs = true
      end

      Person.define_schema do
        title 'Person'
        property :name, String
        property :address, Address, description: 'Primary address', title: 'Main Address'
      end
    end

    it 'merges constraints with $ref' do
      schema = Person.json_schema

      expect(schema['properties']['address']).to eq({
                                                      '$ref' => '#/$defs/Address',
                                                      'description' => 'Primary address',
                                                      'title' => 'Main Address'
                                                    })
    end
  end

  describe 'ref_template method' do
    it 'returns the correct $ref path' do
      expect(Address.ref_template).to eq('#/$defs/Address')
    end
  end

  describe 'interaction with compose/subschemas' do
    let(:base_person) do
      Class.new do
        include EasyTalk::Model

        def self.name
          'BasePerson'
        end
      end
    end

    before do
      stub_const('BasePerson', base_person)

      BasePerson.define_schema do
        title 'BasePerson'
        property :name, String
      end

      EasyTalk.configure do |config|
        config.use_refs = true
      end

      Person.define_schema do
        title 'Person'
        compose T::AllOf[BasePerson]
        property :address, Address
      end
    end

    it 'includes both compose refs and property refs in $defs' do
      schema = Person.json_schema

      expect(schema['$defs']).to have_key('BasePerson')
      expect(schema['$defs']).to have_key('Address')
    end

    it 'uses $ref for property' do
      schema = Person.json_schema

      expect(schema['properties']['address']).to eq({ '$ref' => '#/$defs/Address' })
    end

    it 'includes allOf with compose refs' do
      schema = Person.json_schema

      expect(schema['allOf']).to include({ '$ref' => '#/$defs/BasePerson' })
    end
  end
end
