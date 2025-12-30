# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EasyTalk::Builders::CollectionHelpers do
  describe '#collection_type?' do
    context 'when module is included' do
      let(:including_class) do
        Class.new do
          include EasyTalk::Builders::CollectionHelpers
        end
      end

      it 'returns true' do
        instance = including_class.new
        expect(instance.collection_type?).to be true
      end
    end

    context 'when module is extended' do
      let(:extending_class) do
        Class.new do
          extend EasyTalk::Builders::CollectionHelpers
        end
      end

      it 'returns true as a class method' do
        expect(extending_class.collection_type?).to be true
      end
    end
  end

  describe 'usage in builders' do
    it 'TypedArrayBuilder extends CollectionHelpers' do
      expect(EasyTalk::Builders::TypedArrayBuilder.collection_type?).to be true
    end

    it 'UnionBuilder extends CollectionHelpers' do
      expect(EasyTalk::Builders::UnionBuilder.collection_type?).to be true
    end

    it 'CompositionBuilder extends CollectionHelpers' do
      expect(EasyTalk::Builders::CompositionBuilder.collection_type?).to be true
    end

    it 'AllOfBuilder inherits collection_type? from CompositionBuilder' do
      expect(EasyTalk::Builders::CompositionBuilder::AllOfBuilder.collection_type?).to be true
    end

    it 'AnyOfBuilder inherits collection_type? from CompositionBuilder' do
      expect(EasyTalk::Builders::CompositionBuilder::AnyOfBuilder.collection_type?).to be true
    end

    it 'OneOfBuilder inherits collection_type? from CompositionBuilder' do
      expect(EasyTalk::Builders::CompositionBuilder::OneOfBuilder.collection_type?).to be true
    end
  end

  describe 'contrast with non-collection builders' do
    it 'BaseBuilder returns false for collection_type?' do
      expect(EasyTalk::Builders::BaseBuilder.collection_type?).to be false
    end

    it 'StringBuilder returns false for collection_type?' do
      expect(EasyTalk::Builders::StringBuilder.collection_type?).to be false
    end

    it 'IntegerBuilder returns false for collection_type?' do
      expect(EasyTalk::Builders::IntegerBuilder.collection_type?).to be false
    end

    it 'NumberBuilder returns false for collection_type?' do
      expect(EasyTalk::Builders::NumberBuilder.collection_type?).to be false
    end

    it 'BooleanBuilder returns false for collection_type?' do
      expect(EasyTalk::Builders::BooleanBuilder.collection_type?).to be false
    end

    it 'NullBuilder returns false for collection_type?' do
      expect(EasyTalk::Builders::NullBuilder.collection_type?).to be false
    end
  end
end
