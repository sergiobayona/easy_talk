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
    expect(instance.default_boolean).to eq(false)
  end
end

