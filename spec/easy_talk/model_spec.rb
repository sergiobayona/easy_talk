# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::Model do
  let(:user) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'User'
      end
    end
  end

  it "returns nil because it hasn't been defined" do
    expect(user.schema_definition).to eq({})
  end

  it 'does not inherit schema' do
    expect(user.inherits_schema?).to eq(false)
  end

  it 'returns a ref template' do
    expect(user.ref_template).to eq('#/$defs/User')
  end

  describe '.schema_definition' do
    it 'enhances the schema using the provided block' do
      user.define_schema do
        title 'User'
      end

      expect(user.schema_definition).to be_a(EasyTalk::SchemaDefinition)
    end
  end
end
