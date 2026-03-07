# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'get_type_class should not silently fall back to String' do
  describe 'unrecognized types should return nil, not String' do
    it 'returns nil for an arbitrary object' do
      expect(EasyTalk::TypeIntrospection.get_type_class(Object.new)).to be_nil
    end

    it 'returns nil for an unknown symbol' do
      expect(EasyTalk::TypeIntrospection.get_type_class(:integr)).to be_nil
    end

    it 'returns nil for a non-nilable union like T.any(Integer, Float)' do
      union = T.any(Integer, Float)
      expect(EasyTalk::TypeIntrospection.get_type_class(union)).to be_nil
    end

    it 'returns nil for a composition type like T::AnyOf' do
      composer = T::AnyOf[Integer, String]
      expect(EasyTalk::TypeIntrospection.get_type_class(composer)).to be_nil
    end
  end

  describe 'known types still resolve correctly' do
    it 'resolves String to String' do
      expect(EasyTalk::TypeIntrospection.get_type_class(String)).to eq(String)
    end

    it 'resolves Integer to Integer' do
      expect(EasyTalk::TypeIntrospection.get_type_class(Integer)).to eq(Integer)
    end

    it 'resolves T::Boolean to [TrueClass, FalseClass]' do
      expect(EasyTalk::TypeIntrospection.get_type_class(T::Boolean)).to eq([TrueClass, FalseClass])
    end

    it 'resolves T::Array[String] to Array' do
      expect(EasyTalk::TypeIntrospection.get_type_class(T::Array[String])).to eq(Array)
    end

    it 'resolves T.nilable(String) to String' do
      expect(EasyTalk::TypeIntrospection.get_type_class(T.nilable(String))).to eq(String)
    end

    it 'resolves nil to nil' do
      expect(EasyTalk::TypeIntrospection.get_type_class(nil)).to be_nil
    end

    it 'resolves a known symbol like :string to String' do
      expect(EasyTalk::TypeIntrospection.get_type_class(:string)).to eq(String)
    end
  end
end
