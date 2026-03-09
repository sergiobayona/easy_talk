# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'validating json' do
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
        property :name, String
        property :age, Integer
        property :height, Float
        property :email, Email
      end
    end
  end

  describe 'top level properties' do
    it 'validates the nil name' do
      jim = user.new(name: nil, age: 30, height: 5.9, email: { address: 'jim@test.com', verified: 'true' })
      expect(jim.valid?).to be false
      expect(jim.errors.size).to eq(1)
      expect(jim.errors[:name]).to eq(["can't be blank"])
    end

    # JSON Schema Compliance Gap: Empty String Presence
    # Per JSON Schema spec, an empty string "" is a valid string value.
    # However, ActiveModel's presence validation rejects empty strings.
    # This test documents the current behavior.
    describe 'empty string presence (JSON Schema compliance gap)' do
      it 'currently rejects empty string for required String property (ActiveModel behavior)' do
        jim = user.new(name: '', age: 30, height: 5.9, email: { address: 'jim@test.com', verified: 'true' })
        # Current behavior: empty string fails presence validation
        expect(jim.valid?).to be false
        expect(jim.errors[:name]).to eq(["can't be blank"])
      end

      pending 'should accept empty string for required String property (strict JSON Schema compliance)' do
        jim = user.new(name: '', age: 30, height: 5.9, email: { address: 'jim@test.com', verified: 'true' })
        # Expected behavior per JSON Schema: "" is a valid string, property is present
        expect(jim.valid?).to be true
      end
    end

    it 'validates age attribute is not present' do
      jim = user.new(name: 'Jim', height: 5.9, email: { address: 'jim@test.com', verified: 'true' })
      expect(jim.valid?).to be false
      expect(jim.errors.size).to eq(2)
      expect(jim.errors[:age]).to eq(["can't be blank", 'is not a number'])
    end

    it 'validates email attribute is not present' do
      jim = user.new(name: 'Jim', age: 30, height: 5.9)
      expect(jim.valid?).to be false
      expect(jim.errors.size).to eq(1)
      expect(jim.errors[:email]).to eq(["can't be blank"])
    end

    it 'validates an empty email hash by propagating nested model errors' do
      jim = user.new(name: 'Jim', age: 30, height: 5.9, email: {})
      expect(jim.valid?).to be false
      # An empty hash is auto-instantiated to Email.new({}), which is an object (not nil),
      # so the outer presence validation is satisfied. The nested model's own validation
      # fires instead and its errors are propagated with a dotted-path prefix.
      expect(jim.errors[:'email.address']).to eq(["can't be blank"])
      expect(jim.errors[:'email.verified']).to eq(["can't be blank"])
    end
  end

  it 'validates nested properties' do
    jim = user.new(name: 'Jim', age: 30, height: 5.9, email: { address: 'test@test.com' })
    jim.valid?
    expect(jim.errors['email.verified']).to eq(["can't be blank"])
  end

  it 'errors on invalid age' do
    jim = user.new(name: 'Jim', age: 'thirty', height: 4.5, email: { address: 'test@jim.com', verified: 'true' })
    expect(jim.valid?).to be false
    expect(jim.errors.size).to eq(1)
    expect(jim.errors[:age]).to eq(['is not a number'])
  end

  # Regression: PR #167
  describe 'nested model blank validation' do
    let(:config_class) do
      Class.new do
        include EasyTalk::Model

        def self.name = 'Config'

        define_schema do
          property :timeout, Integer, optional: true
          property :retries, Integer, optional: true
        end
      end
    end

    let(:task_class) do
      config = config_class
      Class.new do
        include EasyTalk::Model

        def self.name = 'Task'

        define_schema do
          property :config, config
        end
      end
    end

    describe 'nested model with all-optional properties' do
      it 'is valid on its own when all properties are nil' do
        instance = config_class.new
        expect(instance.valid?).to be(true),
                                   "Config.new should be valid (all properties are optional) " \
                                   "but got errors: #{instance.errors.full_messages}"
      end

      it 'parent is valid when nested model is valid — even if all nested properties are nil' do
        nested = config_class.new
        expect(nested.valid?).to be(true)

        parent = task_class.new(config: nested)
        expect(parent.valid?).to be(true),
                                 "Parent should be valid when nested model is valid, " \
                                 "but got errors: #{parent.errors.full_messages}"
      end
    end

    describe 'nested model with a mix of optional and required properties' do
      let(:address_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'Address'

          define_schema do
            property :street, String
            property :unit,   String, optional: true
          end
        end
      end

      let(:user_class) do
        addr = address_class
        Class.new do
          include EasyTalk::Model

          def self.name = 'User'

          define_schema do
            property :address, addr
          end
        end
      end

      it "propagates the nested model errors rather than reporting \"can't be blank\"" do
        nested = address_class.new(street: nil, unit: nil)
        expect(nested.valid?).to be(false)

        parent = user_class.new(address: nested)
        parent.valid?

        expect(parent.errors.full_messages).not_to include("Config can't be blank")
        expect(parent.errors.attribute_names.map(&:to_s)).to include(match(/address/))
      end
    end

    describe 'nested model with no declared properties' do
      let(:empty_model_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'EmptyModel'

          define_schema {}
        end
      end

      let(:wrapper_class) do
        inner = empty_model_class
        Class.new do
          include EasyTalk::Model

          def self.name = 'Wrapper'

          define_schema do
            property :inner, inner
          end
        end
      end

      it 'does not report can\'t be blank for a model with no properties' do
        nested = empty_model_class.new
        expect(nested.valid?).to be(true)

        parent = wrapper_class.new(inner: nested)
        expect(parent.valid?).to be(true),
                                 "A nested model with no properties should not be 'blank', " \
                                 "but got errors: #{parent.errors.full_messages}"
      end
    end
  end

  # JSON Schema Compliance Gap: Type Coercion
  # Per JSON Schema spec, a string "30" should NOT be valid for type: integer.
  # Currently, EasyTalk uses ActiveModel's numericality validation which coerces
  # strings to numbers, allowing "30" to pass validation for Integer properties.
  # This test documents the current behavior - when strict type checking is
  # implemented, the pending block should be activated.
  describe 'type coercion (JSON Schema compliance gap)' do
    it 'currently allows string "30" for Integer property (coercion behavior)' do
      jim = user.new(name: 'Jim', age: '30', height: 5.9, email: { address: 'test@jim.com', verified: 'true' })
      # Current behavior: string "30" passes because numericality validator coerces it
      expect(jim.valid?).to be true
    end

    pending 'should reject string "30" for Integer property (strict JSON Schema compliance)' do
      jim = user.new(name: 'Jim', age: '30', height: 5.9, email: { address: 'test@jim.com', verified: 'true' })
      # Expected behavior per JSON Schema: string is not an integer, even if numeric
      expect(jim.valid?).to be false
      expect(jim.errors[:age]).to include('must be an integer')
    end
  end
end
