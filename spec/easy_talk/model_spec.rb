# frozen_string_literal: true

require 'spec_helper'
RSpec.describe EasyTalk::Model do
  before do
    # Define Email class for use in testing
    class Email
      include EasyTalk::Model

      define_schema do
        property :address, String
        property :verified, String
      end
    end
  end

  after do
    # Clean up the Email class after tests
    Object.send(:remove_const, :Email) if Object.const_defined?(:Email)
  end

  let(:user) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'User'
      end

      define_schema do
        title 'User'
        property :name, String
        property :age, Integer
        property :email, Email
      end
    end
  end

  let(:expected_internal_schema) do
    {
      title: 'User',
      properties: {
        name: {
          type: String,
          constraints: {}
        },
        age: {
          type: Integer,
          constraints: {}
        },
        email: {
          type: Email,
          constraints: {}
        }
      }
    }
  end

  it 'returns the name' do
    expect(user.schema_definition.name).to eq 'User'
  end

  it 'returns its attributes' do
    expect(user.properties).to eq(%i[name age email])
  end

  it 'returns a ref template' do
    expect(user.ref_template).to eq('#/$defs/User')
  end

  describe '.schema_definition' do
    it 'enhances the schema using the provided block' do
      expect(user.schema_definition).to be_a(EasyTalk::SchemaDefinition)
    end
  end

  context 'when the class name is nil' do
    let(:user) do
      Class.new do
        include EasyTalk::Model

        def self.name
          nil
        end
      end
    end

    it 'raises an error' do
      expect { user.define_schema {} }.to raise_error(ArgumentError, 'The class must have a name')
    end
  end

  context "when the class doesn't have a name" do
    let(:user) do
      Class.new do
        include EasyTalk::Model
      end
    end

    it 'raises an error' do
      expect { user.define_schema {} }.to raise_error(ArgumentError, 'The class must have a name')
    end
  end

  describe 'the schema' do
    it 'returns the validated internal representation of the schema' do
      expect(user.schema).to be_a(Hash)
    end

    it 'returns the validated internal representation of the schema with the correct type' do
      expect(user.schema[:type]).to eq('object')
    end

    it 'returns the validated internal representation of the schema with the correct title' do
      expect(user.schema[:title]).to eq('User')
    end

    it 'returns the validated internal representation of the schema with properties as a hash' do
      expect(user.schema[:properties]).to be_a(Hash)
    end

    describe "the name property's schema" do
      let(:name_property) { user.schema[:properties][:name] }

      it 'returns an instance of EasyTalk::Property' do
        expect(name_property).to be_a(EasyTalk::Property)
      end

      it "returns the name property's name" do
        expect(name_property.name).to eq(:name)
      end

      it "returns the name property's type" do
        expect(name_property.type).to eq(String)
      end

      it "returns the name property's constraints" do
        expect(name_property.constraints).to eq({})
      end
    end

    describe "the age property's schema" do
      let(:age_property) { user.schema[:properties][:age] }

      it 'returns an instance of EasyTalk::Property' do
        expect(age_property).to be_a(EasyTalk::Property)
      end

      it "returns the age property's name" do
        expect(age_property.name).to eq(:age)
      end

      it "returns the age property's type" do
        expect(age_property.type).to eq(Integer)
      end

      it "returns the age property's constraints" do
        expect(age_property.constraints).to eq({})
      end
    end

    describe 'the json schema' do
      let(:expected_json_schema) do
        {
          type: 'object',
          title: 'User',
          properties: {
            name: {
              type: 'string'
            },
            age: {
              type: 'integer'
            },
            email: {
              type: 'object',
              properties: {
                address: {
                  type: 'string'
                },
                verified: {
                  type: 'string'
                }
              }
            }
          }
        }
      end

      let(:employee) { user.new(name: 'John', age: 21, email: { address: 'john@test.com', verified: 'false' }) }

      it 'returns the JSON schema' do
        expect(user.json_schema).to include_json(expected_json_schema)
      end

      it 'returns the model properties' do
        expect(user.properties).to eq(%i[name age email])
      end

      it "returns the model's name" do
        expect(user.name).to eq('User')
      end

      it 'returns a property' do
        expect(employee.name).to eq('John')
      end

      it 'returns a hash type property' do
        expect(employee.email).to eq(address: 'john@test.com', verified: 'false')
      end

      it 'is valid' do
        expect(employee.valid?).to be(true)
      end
    end
  end

  # Test for the unified schema generation approach
  context 'with unified schema generation' do
    it 'has build_schema as a class method defined in SchemaBase' do
      test_class = Class.new do
        include EasyTalk::Model

        def self.name = 'TestClass'
      end

      expect(test_class.respond_to?(:build_schema, true)).to be true
      expect(test_class.method(:build_schema).owner).to eq(EasyTalk::SchemaBase::ClassMethods)
    end
  end

  # Regression: PR #171
  describe 'define_schema called twice on the same class' do
    let(:model_class) do
      klass = Class.new do
        include EasyTalk::Model

        def self.name = 'DynamicModel'
      end
      klass
    end

    describe 'json_schema reflects the second definition' do
      it 'returns the schema from the most recent define_schema call' do
        model_class.define_schema do
          property :first_name, String
        end

        model_class.define_schema do
          property :email, String
        end

        schema = model_class.json_schema
        props = schema['properties']

        expect(props).to have_key('email'),
                         'json_schema still shows first_name from the stale first definition'
        expect(props).not_to have_key('first_name'),
                             'first_name should be gone after the second define_schema'
      end
    end

    describe 'validations reflect the second definition' do
      it 'enforces constraints from the second define_schema, not the first' do
        model_class.define_schema do
          property :code, String, min_length: 3, max_length: 3
        end

        model_class.define_schema do
          property :code, String
        end

        instance = model_class.new(code: 'X')
        expect(instance.valid?).to be(true),
                                   'Validation from the stale first definition is still active'
      end

      it 'applies presence validation for required properties in the second definition' do
        model_class.define_schema do
          property :old_field, String
        end

        model_class.define_schema do
          property :new_required, String
        end

        instance = model_class.new
        instance.valid?

        expect(instance.errors[:new_required]).to include("can't be blank"),
                                                  'Presence validation was not applied for new_required — ' \
                                                  '@validated_properties retained the old Set'
      end
    end

    describe 'schema_level validations reflect the second definition' do
      it 'applies dependent_required from the second define_schema' do
        model_class.define_schema do
          property :a, String
        end

        model_class.define_schema do
          property :a, String
          property :b, String
          dependent_required a: [:b]
        end

        instance = model_class.new(a: 'hello')
        instance.valid?

        expect(instance.errors).not_to be_empty,
                                       'dependent_required from the second define_schema was silently ' \
                                       'ignored because @schema_level_validations_applied was already true'
      end
    end
  end

  # Regression: PR #165
  describe 'mutable default values' do
    context 'with an Array default' do
      let(:model) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'TaggedItem'

          define_schema do
            property :tags, T::Array[String], default: []
          end
        end
      end

      it 'gives each instance its own copy of the default array' do
        a = model.new
        b = model.new

        a.tags << 'hello'

        expect(b.tags).to eq([]),
                          "Instance b saw a's mutation: b.tags=#{b.tags.inspect}. " \
                          'Mutable default is shared across instances.'
      end

      it 'does not share the same object between instances' do
        a = model.new
        b = model.new

        expect(a.tags.object_id).not_to eq(b.tags.object_id),
                                        'Both instances share the exact same Array object for :tags'
      end
    end

    context 'with a Hash default' do
      let(:model) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'MetadataItem'

          define_schema do
            property :metadata, String, default: { 'key' => 'value' }
          end
        end
      end

      it 'gives each instance its own copy of the default hash' do
        a = model.new
        b = model.new

        a.metadata['injected'] = 'surprise'

        expect(b.metadata).to eq({ 'key' => 'value' }),
                              "Instance b saw a's mutation: b.metadata=#{b.metadata.inspect}. " \
                              'Mutable default is shared across instances.'
      end
    end
  end

  # Regression: PR #163
  describe 'schema cache corruption via merge!' do
    let(:address) do
      Class.new do
        include EasyTalk::Model

        def self.name = 'Address'

        define_schema do
          property :street, String
          property :city, String
        end
      end
    end

    it 'does not corrupt the nested model schema when used with constraints' do
      addr = address
      original_schema = addr.schema.dup

      parent_a = Class.new do
        include EasyTalk::Model

        def self.name = 'ParentA'

        define_schema do
          property :home, addr, title: 'Home Address'
        end
      end

      parent_a.json_schema

      expect(addr.schema).to eq(original_schema),
                             "Address.schema was mutated by ParentA. " \
                             "Expected no :title key, but got: #{addr.schema.inspect}"
    end

    it 'produces correct schemas for both parent models independently' do
      addr = address

      parent_a = Class.new do
        include EasyTalk::Model

        def self.name = 'ParentA'

        define_schema do
          property :home, addr, title: 'Home Address'
        end
      end

      parent_b = Class.new do
        include EasyTalk::Model

        def self.name = 'ParentB'

        define_schema do
          property :work, addr, title: 'Work Address'
        end
      end

      home_schema = parent_a.json_schema['properties']['home']
      work_schema = parent_b.json_schema['properties']['work']

      expect(home_schema['title']).to eq('Home Address'),
                                      "ParentA's :home property should have title 'Home Address', got '#{home_schema['title']}'"
      expect(work_schema['title']).to eq('Work Address'),
                                      "ParentB's :work property should have title 'Work Address', got '#{work_schema['title']}'"
    end

    it 'does not leak constraints between unrelated models using the same nested type' do
      addr = address

      parent_a = Class.new do
        include EasyTalk::Model

        def self.name = 'ParentA'

        define_schema do
          property :location, addr, description: 'A location'
        end
      end

      parent_a.json_schema

      parent_b = Class.new do
        include EasyTalk::Model

        def self.name = 'ParentB'

        define_schema do
          property :place, addr
        end
      end

      place_schema = parent_b.json_schema['properties']['place']

      expect(place_schema).not_to have_key('description'),
                                  "ParentA's description leaked into ParentB's schema: #{place_schema.inspect}"
    end
  end
end
