# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::Builder do
  context 'when building a schema' do
    it 'returns a bare json object' do
      expect(described_class.build_schema({})).to eq({ type: 'object', properties: {}, required: [] })
    end

    it 'includes a title' do
      expect(described_class.build_schema(title: 'Title')).to eq({
                                                                   title: 'Title',
                                                                   type: 'object',
                                                                   properties: {},
                                                                   required: []
                                                                 })
    end

    it 'includes a description' do
      obj = described_class.build_schema(description: 'Description')
      expect(obj).to eq({
                          description: 'Description',
                          type: 'object',
                          properties: {},
                          required: []
                        })
    end

    it 'includes the property' do
      obj = described_class.build_schema(properties: { name: { type: String } })
      expect(obj).to be_a(Hash)
      expect(obj[:properties]).to be_a(Hash)
      expect(obj[:properties][:name]).to be_a(EasyTalk::Property)
    end
  end
end
