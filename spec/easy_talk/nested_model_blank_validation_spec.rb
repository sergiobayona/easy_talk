# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'nested model presence validation' do
  # apply_object_validations uses an "all_properties_blank" heuristic to detect
  # whether a nested model is blank. It checks if every declared property is nil
  # or empty — and if so, reports "can't be blank" without ever calling
  # nested_object.valid?
  #
  # This breaks the fundamental contract: if Nested.new.valid? is true, then
  # Parent.new(nested: Nested.new).valid? must not report a blank/presence error.

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
      # This is the core contract: parent validity must agree with nested validity.
      # The bug causes the parent to report "can't be blank" because all nested
      # properties are nil, without ever delegating to nested_object.valid?.
      nested = config_class.new
      expect(nested.valid?).to be(true) # precondition

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
      # street is required but nil — nested model is invalid
      nested = address_class.new(street: nil, unit: nil)
      expect(nested.valid?).to be(false) # precondition

      parent = user_class.new(address: nested)
      parent.valid?

      # Should surface the real nested error, not swallow it under "can't be blank"
      expect(parent.errors.full_messages).not_to include("Config can't be blank")
      expect(parent.errors.attribute_names.map(&:to_s)).to include(match(/address/))
    end
  end

  describe 'nested model with no declared properties' do
    let(:empty_model_class) do
      Class.new do
        include EasyTalk::Model

        def self.name = 'EmptyModel'

        define_schema {} # no properties
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
      # all? on an empty collection returns true, so the heuristic always fires here.
      # A model with no properties should be considered valid (nothing can be wrong).
      nested = empty_model_class.new
      expect(nested.valid?).to be(true) # precondition

      parent = wrapper_class.new(inner: nested)
      expect(parent.valid?).to be(true),
                               "A nested model with no properties should not be 'blank', " \
                               "but got errors: #{parent.errors.full_messages}"
    end
  end
end
