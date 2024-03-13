# frozen_string_literal: true

require 'spec_helper'
require 'easy_talk/schema_definition'

RSpec.describe EasyTalk::SchemaDefinition do
  let(:schema_definition) { {} }
  let(:klass) { double('Class') }
  subject { described_class.new(klass, schema_definition) }

  describe '#initialize' do
    it 'sets the klass and schema_definition' do
      expect(subject.klass).to eq(klass)
      expect(schema_definition).to eq({})
    end
  end

  describe 'property' do
    it 'adds a property to the schema_definition' do
      subject.property(:name, String, minimum: 1, maximum: 100)
      expect(schema_definition[:properties]).to eq({ name: { type: String, constraints: { minimum: 1, maximum: 100 } } })
    end
  end

  describe 'with compositional keywords i.e. allOf, anyOf, oneOf...' do
    it 'raises an error when the the argument is not a class that includes the EasyTalk::Model' do
      expect { subject.all_of('allOf') }.to raise_error(ArgumentError, 'Invalid argument: allOf. Must be a class that includes EasyTalk::Model')
    end

    describe 'with a valid class' do
      let(:model) do
        Class.new do
          include EasyTalk::Model

          def self.name
            'Model'
          end

          define_schema do
            property(:myprop, String, minimum: 1, maximum: 100)
          end
        end
      end

      it 'adds a reference to the model on the all_of node' do
        subject.all_of(model)
        expect(schema_definition[:all_of]).to eq([{ "$ref": model.ref_template }])
      end

      it 'adds a reference to the model on the any_of node' do
        subject.any_of(model)
        expect(schema_definition[:any_of]).to eq([{ "$ref": model.ref_template }])
      end

      it 'adds a reference to the model on the the one_of node' do
        subject.one_of(model)
        expect(schema_definition[:one_of]).to eq([{ "$ref": model.ref_template }])
      end

      it 'adds the referenced model to the defs node' do
        property = model.schema_definition[:properties][:myprop]
        subject.all_of(model)
        expect(schema_definition[:defs]).to eq({ Model: { properties: { myprop: property }, required: [:myprop], type: 'object' } })
      end
    end
  end

  describe 'keywords' do
    it 'adds a keyword to the schema_definition' do
      subject.title('Title')
      subject.description('Description')
      subject.default('Default')
      subject.enum(%w[one two three])
      subject.pattern('^[0-9]{5}(?:-[0-9]{4})?$')
      subject.format('email')
      subject.minimum(1)
      subject.maximum(100)
      subject.min_items(1)
      subject.max_items(100)
      subject.additional_properties(false)
      subject.unique_items(true)
      subject.const('Const')
      subject.content_media_type('ContentMediaType')
      subject.content_encoding('ContentEncoding')

      expect(schema_definition[:title]).to eq('Title')
      expect(schema_definition[:description]).to eq('Description')
      expect(schema_definition[:default]).to eq('Default')
      expect(schema_definition[:enum]).to eq(%w[one two three])
      expect(schema_definition[:pattern]).to eq('^[0-9]{5}(?:-[0-9]{4})?$')
      expect(schema_definition[:format]).to eq('email')
      expect(schema_definition[:minimum]).to eq(1)
      expect(schema_definition[:maximum]).to eq(100)
      expect(schema_definition[:min_items]).to eq(1)
      expect(schema_definition[:max_items]).to eq(100)
      expect(schema_definition[:additional_properties]).to eq(false)
      expect(schema_definition[:unique_items]).to eq(true)
      expect(schema_definition[:const]).to eq('Const')
      expect(schema_definition[:content_media_type]).to eq('ContentMediaType')
      expect(schema_definition[:content_encoding]).to eq('ContentEncoding')
    end
  end
end
