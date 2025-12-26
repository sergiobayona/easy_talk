# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'default values' do
  let(:default_class) do
    Class.new do
      include(EasyTalk::Model)

      def self.name
        'DefaultClass'
      end

      define_schema do
        property :default_enum, String, enum: %w[one two three], default: 'two'
        property :default_string, String, default: 'foo'
        property :default_boolean, T::Boolean, default: false
      end
    end
  end

  it('applies default values correctly') do
    instance = default_class.new

    expect(instance.default_enum).to eq('two')
    expect(instance.default_string).to eq('foo')
    expect(instance.default_boolean).to be(false)
  end

  it 'preserves explicitly passed nil values' do
    instance = default_class.new(default_string: nil, default_enum: nil)

    expect(instance.default_string).to be_nil
    expect(instance.default_enum).to be_nil
    # Boolean not passed, so default applies
    expect(instance.default_boolean).to be(false)
  end

  it 'applies defaults only for unprovided attributes' do
    instance = default_class.new(default_string: 'custom')

    expect(instance.default_string).to eq('custom')
    expect(instance.default_enum).to eq('two')
    expect(instance.default_boolean).to be(false)
  end

  it 'handles string keys in attributes hash' do
    instance = default_class.new('default_string' => nil)

    expect(instance.default_string).to be_nil
    # Other defaults still apply
    expect(instance.default_enum).to eq('two')
    expect(instance.default_boolean).to be(false)
  end
end
