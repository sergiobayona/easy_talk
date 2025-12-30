# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::RefHelper do
  let(:model_class) do
    Class.new do
      include EasyTalk::Model

      def self.name
        'TestModel'
      end

      define_schema do
        property :name, String
      end
    end
  end

  let(:non_model_class) do
    Class.new do
      def self.name
        'PlainClass'
      end
    end
  end

  describe '.should_use_ref?' do
    context 'with non-model type' do
      it 'returns false for plain classes' do
        expect(described_class.should_use_ref?(non_model_class, {})).to be false
      end

      it 'returns false for primitive types' do
        expect(described_class.should_use_ref?(String, {})).to be false
        expect(described_class.should_use_ref?(Integer, {})).to be false
      end
    end

    context 'with EasyTalk model' do
      context 'when ref constraint is explicitly set' do
        it 'returns true when ref: true' do
          expect(described_class.should_use_ref?(model_class, { ref: true })).to be true
        end

        it 'returns false when ref: false' do
          expect(described_class.should_use_ref?(model_class, { ref: false })).to be false
        end
      end

      context 'when using global configuration' do
        around do |example|
          original_use_refs = EasyTalk.configuration.use_refs
          example.run
          EasyTalk.configuration.use_refs = original_use_refs
        end

        it 'returns true when global use_refs is true' do
          EasyTalk.configuration.use_refs = true
          expect(described_class.should_use_ref?(model_class, {})).to be true
        end

        it 'returns false when global use_refs is false' do
          EasyTalk.configuration.use_refs = false
          expect(described_class.should_use_ref?(model_class, {})).to be false
        end

        it 'per-property constraint overrides global config' do
          EasyTalk.configuration.use_refs = true
          expect(described_class.should_use_ref?(model_class, { ref: false })).to be false
        end
      end
    end
  end

  describe '.should_use_ref_for_type?' do
    context 'with non-model type' do
      it 'returns false' do
        expect(described_class.should_use_ref_for_type?(String, {})).to be false
      end
    end

    context 'with EasyTalk model' do
      around do |example|
        original_use_refs = EasyTalk.configuration.use_refs
        example.run
        EasyTalk.configuration.use_refs = original_use_refs
      end

      it 'respects ref constraint over global config' do
        EasyTalk.configuration.use_refs = false
        expect(described_class.should_use_ref_for_type?(model_class, { ref: true })).to be true
      end

      it 'falls back to global config when no constraint' do
        EasyTalk.configuration.use_refs = true
        expect(described_class.should_use_ref_for_type?(model_class, {})).to be true
      end
    end
  end

  describe '.build_ref_schema' do
    it 'creates schema with $ref pointing to model' do
      result = described_class.build_ref_schema(model_class, {})
      expect(result).to eq({ '$ref': '#/$defs/TestModel' })
    end

    it 'excludes ref constraint from output' do
      result = described_class.build_ref_schema(model_class, { ref: true })
      expect(result).to eq({ '$ref': '#/$defs/TestModel' })
      expect(result).not_to have_key(:ref)
    end

    it 'excludes optional constraint from output' do
      result = described_class.build_ref_schema(model_class, { optional: true })
      expect(result).to eq({ '$ref': '#/$defs/TestModel' })
      expect(result).not_to have_key(:optional)
    end

    it 'preserves other constraints' do
      result = described_class.build_ref_schema(model_class, { title: 'Test', description: 'A test model' })
      expect(result).to eq({
                             '$ref': '#/$defs/TestModel',
                             title: 'Test',
                             description: 'A test model'
                           })
    end

    it 'handles multiple constraints correctly' do
      result = described_class.build_ref_schema(model_class, {
                                                  ref: true,
                                                  optional: true,
                                                  title: 'Test',
                                                  description: 'Desc'
                                                })
      expect(result.keys).to contain_exactly(:$ref, :title, :description)
    end
  end
end
