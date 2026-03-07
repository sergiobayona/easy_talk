# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'T.nilable(T::Boolean) allows nil in validation' do
  # apply_boolean_validations only checks optional?, not nilable_type?.
  # When a property is T.nilable(T::Boolean), nil is explicitly allowed by
  # JSON Schema, but the validator rejects it with two errors:
  #   - inclusion: nil is not in [true, false]
  #   - apply_boolean_presence_validation: adds :blank for nil
  #
  # This is the same class of bug fixed for enum and numeric validators.

  let(:model) do
    Class.new do
      include EasyTalk::Model

      def self.name = 'FlagModel'

      define_schema do
        property :enabled, T.nilable(T::Boolean)
      end
    end
  end

  it 'accepts nil — nil is explicitly allowed by T.nilable' do
    instance = model.new(enabled: nil)
    expect(instance.valid?).to be(true),
                               "Expected nil to be valid for T.nilable(T::Boolean), " \
                               "but got errors: #{instance.errors[:enabled]}"
  end

  it 'still accepts true' do
    expect(model.new(enabled: true).valid?).to be(true)
  end

  it 'still accepts false' do
    expect(model.new(enabled: false).valid?).to be(true)
  end

  it 'still rejects non-boolean values' do
    instance = model.new(enabled: 'yes')
    expect(instance.valid?).to be(false)
    expect(instance.errors[:enabled]).not_to be_empty
  end

  context 'required T::Boolean (non-nilable) still rejects nil' do
    let(:required_model) do
      Class.new do
        include EasyTalk::Model

        def self.name = 'RequiredFlagModel'

        define_schema do
          property :enabled, T::Boolean
        end
      end
    end

    it 'rejects nil for a required boolean property' do
      instance = required_model.new(enabled: nil)
      expect(instance.valid?).to be(false)
      expect(instance.errors[:enabled]).not_to be_empty
    end
  end
end
