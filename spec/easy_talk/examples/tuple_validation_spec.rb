# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Tuple Validation with T::Tuple' do
  describe 'schema generation' do
    context 'basic T::Tuple usage' do
      let(:model_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'TupleTypeModel'

          define_schema do
            property :flags, T::Tuple[T::Boolean, T::Boolean], additional_items: false
            property :record, T::Tuple[String, Integer]
          end
        end
      end

      it 'generates correct JSON schema for T::Tuple[Boolean, Boolean]' do
        schema = model_class.json_schema
        expect(schema['properties']['flags']).to eq({
                                                      'type' => 'array',
                                                      'items' => [
                                                        { 'type' => 'boolean' },
                                                        { 'type' => 'boolean' }
                                                      ],
                                                      'additionalItems' => false
                                                    })
      end

      it 'generates correct JSON schema for T::Tuple[String, Integer]' do
        schema = model_class.json_schema
        expect(schema['properties']['record']).to eq({
                                                       'type' => 'array',
                                                       'items' => [
                                                         { 'type' => 'string' },
                                                         { 'type' => 'integer' }
                                                       ]
                                                     })
      end
    end

    context 'T::Tuple with typed additionalItems' do
      let(:model_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'TypedExtrasTuple'

          define_schema do
            property :data, T::Tuple[String], additional_items: Integer
          end
        end
      end

      it 'generates additionalItems with type schema' do
        schema = model_class.json_schema
        expect(schema['properties']['data']['additionalItems']).to eq({ 'type' => 'integer' })
      end
    end

    context 'T::Tuple with array constraints' do
      let(:model_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'ConstrainedTuple'

          define_schema do
            property :coords, T::Tuple[Float, Float],
                     additional_items: false,
                     min_items: 2,
                     unique_items: true
          end
        end
      end

      it 'includes all constraints in schema' do
        schema = model_class.json_schema
        expect(schema['properties']['coords']).to include(
          'type' => 'array',
          'minItems' => 2,
          'uniqueItems' => true,
          'additionalItems' => false
        )
      end
    end

    context 'T::Tuple with mixed types' do
      let(:model_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'MixedTuple'

          define_schema do
            property :data, T::Tuple[String, Integer, T::Boolean]
          end
        end
      end

      it 'generates correct schema for mixed type tuple' do
        schema = model_class.json_schema
        expect(schema['properties']['data']).to eq({
                                                     'type' => 'array',
                                                     'items' => [
                                                       { 'type' => 'string' },
                                                       { 'type' => 'integer' },
                                                       { 'type' => 'boolean' }
                                                     ]
                                                   })
      end
    end
  end

  describe 'validation' do
    context 'with T::Tuple[Boolean, Boolean]' do
      let(:model_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'TupleFlagModel'

          define_schema do
            property :flags, T::Tuple[T::Boolean, T::Boolean], additional_items: false
          end
        end
      end

      it 'validates correct tuple input' do
        instance = model_class.new(flags: [true, false])
        expect(instance).to be_valid
      end

      it 'validates with single item (items are optional by default)' do
        instance = model_class.new(flags: [true])
        expect(instance).to be_valid
      end

      it 'rejects wrong type at position 0' do
        instance = model_class.new(flags: [1, false])
        expect(instance).not_to be_valid
        expect(instance.errors[:flags]).to include('item at index 0 must be a TrueClass or FalseClass')
      end

      it 'rejects wrong type at position 1' do
        instance = model_class.new(flags: [true, 'false'])
        expect(instance).not_to be_valid
        expect(instance.errors[:flags]).to include('item at index 1 must be a TrueClass or FalseClass')
      end

      it 'rejects extra items when additional_items: false' do
        instance = model_class.new(flags: [true, false, nil])
        expect(instance).not_to be_valid
        expect(instance.errors[:flags]).to include('must have at most 2 items')
      end
    end

    context 'with T::Tuple[String, Integer]' do
      let(:model_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'TupleRecordModel'

          define_schema do
            property :record, T::Tuple[String, Integer], additional_items: false
          end
        end
      end

      it 'validates correct tuple input' do
        instance = model_class.new(record: ['name', 42])
        expect(instance).to be_valid
      end

      it 'rejects swapped types' do
        instance = model_class.new(record: [42, 'name'])
        expect(instance).not_to be_valid
        expect(instance.errors[:record]).to include('item at index 0 must be a String')
        expect(instance.errors[:record]).to include('item at index 1 must be a Integer')
      end
    end

    context 'with typed additional_items' do
      let(:model_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'TupleTypedExtras'

          define_schema do
            property :data, T::Tuple[String], additional_items: Integer
          end
        end
      end

      it 'validates correct extra items matching type' do
        instance = model_class.new(data: ['header', 1, 2, 3])
        expect(instance).to be_valid
      end

      it 'rejects extra items of wrong type' do
        instance = model_class.new(data: ['header', 1, 'wrong'])
        expect(instance).not_to be_valid
        expect(instance.errors[:data]).to include('item at index 2 must be a Integer')
      end
    end

    context 'with additional_items: true (any extras allowed)' do
      let(:model_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'FlexibleTuple'

          define_schema do
            property :data, T::Tuple[String], additional_items: true
          end
        end
      end

      it 'allows any extra items' do
        instance = model_class.new(data: ['header', 1, true, nil, 'anything'])
        expect(instance).to be_valid
      end
    end

    context 'without additionalItems (any extras allowed by default)' do
      let(:model_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'DefaultTuple'

          define_schema do
            property :data, T::Tuple[String]
          end
        end
      end

      it 'allows any extra items by default' do
        instance = model_class.new(data: ['header', 1, true, nil])
        expect(instance).to be_valid
      end
    end

    context 'combined with array constraints' do
      let(:model_class) do
        Class.new do
          include EasyTalk::Model

          def self.name = 'StrictTuple'

          define_schema do
            property :coords, T::Tuple[Float, Float],
                     additional_items: false,
                     min_items: 2,
                     unique_items: true
          end
        end
      end

      it 'validates all constraints together' do
        instance = model_class.new(coords: [1.5, 2.5])
        expect(instance).to be_valid
      end

      it 'rejects too few items' do
        instance = model_class.new(coords: [1.5])
        expect(instance).not_to be_valid
        expect(instance.errors[:coords].join).to include('minimum')
      end

      it 'rejects duplicate items' do
        instance = model_class.new(coords: [1.5, 1.5])
        expect(instance).not_to be_valid
        expect(instance.errors[:coords]).to include('must contain unique items')
      end
    end
  end

  describe 'EasyTalk::Types::Tuple class' do
    it 'stores types correctly' do
      tuple = T::Tuple[String, Integer, T::Boolean]
      expect(tuple.types).to eq([String, Integer, T::Boolean])
    end

    it 'raises error for empty types' do
      expect { EasyTalk::Types::Tuple.new }.to raise_error(ArgumentError, 'Tuple requires at least one type')
    end

    it 'raises error for nil types' do
      expect { T::Tuple[String, nil] }.to raise_error(ArgumentError, 'Tuple types cannot be nil')
    end

    it 'has a readable to_s representation' do
      tuple = T::Tuple[String, Integer]
      expect(tuple.to_s).to eq('T::Tuple[String, Integer]')
    end

    it 'handles anonymous classes in to_s' do
      anonymous_class = Class.new
      tuple = EasyTalk::Types::Tuple.new(String, anonymous_class)
      # Should not raise and should fall back to to_s for anonymous class
      expect(tuple.to_s).to match(/T::Tuple\[String, #<Class:0x/)
    end
  end
end
