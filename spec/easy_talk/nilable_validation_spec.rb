# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'nilable properties with constraints allow nil in validation' do
  # T.nilable(Type) means the JSON Schema allows null.
  # The generated ActiveModel validations must not reject nil for these properties.
  # Two validators fail to respect this: enum (allow_nil: optional? only) and
  # numericality (no allow_nil at all).

  context 'enum constraint on a nilable property' do
    let(:model) do
      Class.new do
        include EasyTalk::Model

        def self.name = 'StatusModel'

        define_schema do
          property :status, T.nilable(String), enum: %w[active inactive]
        end
      end
    end

    it 'accepts nil — nil is explicitly allowed by T.nilable' do
      instance = model.new(status: nil)
      expect(instance.valid?).to be(true),
                                 "Expected nil to be valid for T.nilable(String) with enum, " \
                                 "but got errors: #{instance.errors[:status]}"
    end

    it 'still rejects values outside the enum' do
      instance = model.new(status: 'unknown')
      expect(instance.valid?).to be(false)
      expect(instance.errors[:status]).not_to be_empty
    end

    it 'still accepts values inside the enum' do
      expect(model.new(status: 'active').valid?).to be(true)
    end
  end

  context 'minimum/maximum constraint on a nilable integer property' do
    let(:model) do
      Class.new do
        include EasyTalk::Model

        def self.name = 'AgeModel'

        define_schema do
          property :age, T.nilable(Integer), minimum: 0, maximum: 150
        end
      end
    end

    it 'accepts nil — nil is explicitly allowed by T.nilable' do
      instance = model.new(age: nil)
      expect(instance.valid?).to be(true),
                                 "Expected nil to be valid for T.nilable(Integer) with minimum/maximum, " \
                                 "but got errors: #{instance.errors[:age]}"
    end

    it 'still rejects values below minimum' do
      instance = model.new(age: -1)
      expect(instance.valid?).to be(false)
      expect(instance.errors[:age]).not_to be_empty
    end

    it 'still accepts values within range' do
      expect(model.new(age: 30).valid?).to be(true)
    end
  end

  context 'minimum constraint on a nilable float property' do
    let(:model) do
      Class.new do
        include EasyTalk::Model

        def self.name = 'ScoreModel'

        define_schema do
          property :score, T.nilable(Float), minimum: 0.0
        end
      end
    end

    it 'accepts nil — nil is explicitly allowed by T.nilable' do
      instance = model.new(score: nil)
      expect(instance.valid?).to be(true),
                                 "Expected nil to be valid for T.nilable(Float) with minimum, " \
                                 "but got errors: #{instance.errors[:score]}"
    end
  end
end
