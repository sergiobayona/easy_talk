# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::ActiveModelType do
  before do
    profile_class = Class.new do
      include EasyTalk::Schema
    end
    stub_const('ActiveModelTypeProfile', profile_class)
    ActiveModelTypeProfile.define_schema do
      property :title, String
    end

    settings_class = Class.new do
      include EasyTalk::Schema
    end
    stub_const('ActiveModelTypeSettings', settings_class)
    ActiveModelTypeSettings.define_schema do
      property :name, String
      property :age, Integer
      property :active, T::Boolean
      property :scores, T::Array[Integer], optional: true
      property :profile, ActiveModelTypeProfile, optional: true
      property :profiles, T::Array[ActiveModelTypeProfile], optional: true
      property :record, T::Tuple[String, Integer], optional: true
      property :role, String, default: 'member'
    end
  end

  let(:type) { described_class.new(ActiveModelTypeSettings) }

  it 'casts primitives from strings' do
    result = type.cast('name' => 123, 'age' => '42', 'active' => 'false')

    expect(result).to be_a(ActiveModelTypeSettings)
    expect(result.name).to eq('123')
    expect(result.age).to eq(42)
    expect(result.active).to be(false)
  end

  it 'casts typed arrays' do
    result = type.cast('scores' => ['1', 2, '3'])

    expect(result.scores).to eq([1, 2, 3])
  end

  it 'casts nested schemas' do
    result = type.cast('profile' => { 'title' => 'Captain' })

    expect(result.profile).to be_a(ActiveModelTypeProfile)
    expect(result.profile.title).to eq('Captain')
  end

  it 'accepts JSON strings' do
    result = type.cast('{"name":"Ada","age":"7","active":"true"}')

    expect(result.name).to eq('Ada')
    expect(result.age).to eq(7)
    expect(result.active).to be(true)
  end

  describe '#changed_in_place?' do
    it 'does not mark equivalent values as changed (avoids always-dirty attributes)' do
      new_value = type.cast(
        'name' => 'Ada',
        'age' => 7,
        'active' => true,
        'profile' => { 'title' => 'Captain' }
      )

      raw_old_value = {
        'name' => 'Ada',
        'age' => 7,
        'active' => true,
        'scores' => nil,
        'profile' => { 'title' => 'Captain' },
        'role' => 'member'
      }

      expect(type.changed_in_place?(raw_old_value, new_value)).to be(false)
    end

    it 'detects changes by comparing the serialized data' do
      new_value = type.cast('name' => 'Ada', 'age' => 8, 'active' => true)
      raw_old_value = {
        'name' => 'Ada',
        'age' => 7,
        'active' => true,
        'scores' => nil,
        'profile' => nil,
        'role' => 'member'
      }

      expect(type.changed_in_place?(raw_old_value, new_value)).to be(true)
    end

    it 'accepts JSON strings for raw values' do
      new_value = type.cast(
        'name' => 'Ada',
        'age' => 7,
        'active' => true,
        'profile' => { 'title' => 'Captain' }
      )

      raw_old_value = '{"name":"Ada","age":7,"active":true,"profile":{"title":"Captain"},"role":"member"}'

      expect(type.changed_in_place?(raw_old_value, new_value)).to be(false)
    end

    it 'treats defaults as unchanged when missing in raw value' do
      new_value = type.cast('name' => 'Ada', 'age' => 7, 'active' => true)
      raw_old_value = { 'name' => 'Ada', 'age' => 7, 'active' => true }

      expect(type.changed_in_place?(raw_old_value, new_value)).to be(false)
    end

    it 'normalizes symbol and string keys (including nested)' do
      new_value = type.cast(
        'name' => 'Ada',
        'age' => 7,
        'active' => true,
        'profile' => { 'title' => 'Captain' }
      )

      raw_old_value = {
        name: 'Ada',
        'age' => 7,
        active: true,
        profile: { title: 'Captain' },
        role: 'member'
      }

      expect(type.changed_in_place?(raw_old_value, new_value)).to be(false)
    end

    it 'does not depend on object identity for schema instances' do
      raw_old_value = type.cast(
        'name' => 'Ada',
        'age' => 7,
        'active' => true,
        'profile' => { 'title' => 'Captain' }
      )
      new_value = type.cast(
        'name' => 'Ada',
        'age' => 7,
        'active' => true,
        'profile' => { 'title' => 'Captain' }
      )

      expect(type.changed_in_place?(raw_old_value, new_value)).to be(false)
    end

    it 'handles nested arrays of schemas' do
      new_value = type.cast(
        'name' => 'Ada',
        'age' => 7,
        'active' => true,
        'profiles' => [{ 'title' => 'Captain' }]
      )

      raw_old_value = {
        'name' => 'Ada',
        'age' => 7,
        'active' => true,
        'profiles' => [{ 'title' => 'Captain' }],
        'role' => 'member'
      }

      expect(type.changed_in_place?(raw_old_value, new_value)).to be(false)
    end

    it 'coerces tuple values for comparison' do
      new_value = type.cast('name' => 'Ada', 'age' => 7, 'active' => true, 'record' => ['Ada', 7])
      raw_old_value = { 'name' => 'Ada', 'age' => 7, 'active' => true, 'record' => %w[Ada 7] }

      expect(type.changed_in_place?(raw_old_value, new_value)).to be(false)
    end

    it 'ignores unknown keys for schema types' do
      new_value = type.cast('name' => 'Ada', 'age' => 7, 'active' => true)
      raw_old_value = { 'name' => 'Ada', 'age' => 7, 'active' => true, 'unknown' => 'extra' }

      expect(type.changed_in_place?(raw_old_value, new_value)).to be(false)
    end
  end
end
