# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EsquemaBase::Builder do
  it 'returns a bare json object' do
    expect(described_class.build_schema({})).to include_json({ "type": 'object' })
  end

  it 'includes a title' do
    expect(described_class.build_schema(title: 'Title')).to include_json({ "title": 'Title', "type": 'object' })
  end

  it 'includes a description' do
    json = described_class.build_schema(description: 'Description')
    expect(json).to include_json({
                                   "description": 'Description',
                                   "type": 'object'
                                 })
  end

  it 'includes the property' do
    json = described_class.build_schema(properties: { name: { type: String } })
    expect(json).to include_json({
                                   "type": 'object',
                                   "properties": {
                                     "name": {
                                       "type": 'string'
                                     }
                                   }
                                 })
  end
end
