# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'EasyTalk::Schema preserves false values on initialization' do
  # EasyTalk::Schema initializes properties with:
  #   value = attributes[prop_name] || attributes[prop_name.to_s]
  #
  # The || operator treats false as falsy, so when a caller passes false
  # with a symbol key the lookup falls through to the string-key side,
  # which returns nil. The property is silently set to nil instead of false.
  #
  # EasyTalk::Model is NOT affected — it delegates to ActiveModel's
  # assign_attributes, which calls the setter directly.

  let(:schema_class) do
    Class.new do
      include EasyTalk::Schema

      def self.name = 'FeatureFlags'

      define_schema do
        property :enabled,  T::Boolean
        property :archived, T::Boolean
        property :count,    Integer
      end
    end
  end

  describe 'symbol-key assignment' do
    it 'preserves false for a boolean property' do
      instance = schema_class.new(enabled: false)
      expect(instance.enabled).to be(false),
                                  "Expected false but got #{instance.enabled.inspect} — " \
                                  'false was silently lost via the || lookup'
    end

    it 'preserves false when multiple booleans are passed' do
      instance = schema_class.new(enabled: false, archived: false)
      expect(instance.enabled).to be(false)
      expect(instance.archived).to be(false)
    end

    it 'preserves true (sanity check — truthy values are unaffected)' do
      instance = schema_class.new(enabled: true)
      expect(instance.enabled).to be(true)
    end

    it 'preserves 0 (sanity check — 0 is truthy in Ruby, so unaffected)' do
      instance = schema_class.new(count: 0)
      expect(instance.count).to eq(0)
    end
  end

  describe 'string-key assignment' do
    it 'preserves false when passed with string keys' do
      # String-key false works because: nil || false == false
      instance = schema_class.new('enabled' => false)
      expect(instance.enabled).to be(false)
    end
  end

  describe 'mixed false and nil' do
    it 'distinguishes between an explicitly passed false and an absent key' do
      with_false = schema_class.new(enabled: false)
      with_nil   = schema_class.new(enabled: nil)
      absent     = schema_class.new

      # All three end up as nil due to the bug — they should differ
      expect(with_false.enabled).to be(false)  # fails: gets nil
      expect(with_nil.enabled).to be_nil
      expect(absent.enabled).to be_nil
    end
  end
end
